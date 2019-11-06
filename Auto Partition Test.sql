ALTER PROC PartitionCreate.usp_CreateNewPartitions
AS /****************************************************************************
* This proc will look at the last partition that was created and use todays	*
* date to see if a future partition is needed. The idea is once we have		*
* reached the point of the right edge of the parition function will be		*
* reached within the next partition frequency lets make a new empty			*
* empty partition. We use the table PartitionCreate.PartitionConfig for the	*
* partition configuration. We cycle through all of the tables listed and	*
* if there is nothing to do we check the next one. If there is something to	*
* be created we then create the script and execute it.						*
* This does not like a configurations that split a year like 2015Q4_2016Q1  *
* That was such	an edge case I figured to not try to program for it.		*
* It also does not like a string right edge. So keep it to dates or numbers	*
*---------------------------------------------------------------------------* 
* Uses PartitionCreate.ReplacePatternStringForPartitions to do the			*
* replacment. Below are the replacments it will handle						*
* The replace part of the pattern will be inclosed in curly brackets { }	*
* W = Week number															*
* M = Month Number															*
* Y = last 2 digits of Year													*
* Q = Quarter Number														*
* +N = Base Plus N  i.e. {Y+1Y} for 2015 would be 1516						*
* Example: Fact_Sales_{CY}_(Q} would become Fact_Sales_2015_Q4				*
*---------------------------------------------------------------------------*
* Uses PartitionCreate.CaculateRefDate to caculate dates. Did this in 2		*
* places so made a function													*
****************************************************************************/

    DECLARE @DataFilePath NVARCHAR(255) ,
        @TableName sysname ,
        @Frequency NVARCHAR(10) ,
        @FrequencyInterval INT ,
        @PartitionPattern NVARCHAR(255) ,
        @PartitionFunctionName sysname ,
        @PartitionSchemeName sysname ,
        @RightEdgePattern NVARCHAR(255) ,
        @NewRightEdgeValue NVARCHAR(255) ,
        @CurrentRightEdgeValueActual SQL_VARIANT ,
        @FileNamePattern VARCHAR(255) ,
        @NewFileName NVARCHAR(255) ,
        @NewFileAndPath NVARCHAR(255) ,
        @FileGroupName NVARCHAR(255) ,
        @SQL NVARCHAR(2000) ,
        @NewFileSize NVARCHAR(255) ,
        @NewFileGrowthSetting NVARCHAR(255) ,
        @Quote NCHAR(1) ,
        @Space NCHAR(1) ,
        @Comma NCHAR(1) ,
        @QuComSpa NCHAR(3) ,
        @RefDate DATE ,
        @DatabaseName sysname ,
        @Today DATE ,
        @LastPartitionCreated sysname ,
        @NeedNewPartition BIT ,
        @TestInterval INT ,
        @TestRefDate DATE ,
        @TestRightEdgeValue NVARCHAR(255);

	/* These make the code easier to read */
    SET @Quote = '''';
    SET @Space = ' ';
    SET @Comma = ',';
    SET @QuComSpa = ''', ';
    SET @DatabaseName = DB_NAME(); 

	/* go through configuration table to look at each partition  */
    DECLARE cTables CURSOR FAST_FORWARD READ_ONLY
    FOR
        SELECT  TableName ,
                Frequency ,
                FrequencyInterval ,
                PartitionPattern ,
                PartitionFunctionName ,
                PartitionSchemeName ,
                FileNamePattern ,
                NewFileSize ,
                NewFileGrowthSetting ,
                DataFilePath ,
                RightEdgePattern
        FROM    PartitionCreate.PartitionConfig
        WHERE   AutoCreate = 1;


    OPEN cTables;

    FETCH NEXT FROM cTables INTO @TableName, @Frequency, @FrequencyInterval,
        @PartitionPattern, @PartitionFunctionName, @PartitionSchemeName,
        @FileNamePattern, @NewFileSize, @NewFileGrowthSetting, @DataFilePath,
        @RightEdgePattern; 

    WHILE @@FETCH_STATUS = 0
        BEGIN

            SET @Today = GETDATE();

			/* Look at the last partition created */
            WITH    TablePartitions ( PartNum, TableFileGroup, value )
                      AS ( SELECT   p.partition_number AS PartNum ,
                                    fg.name AS TableFileGroup ,
                                    rv.value
                           FROM     sys.partitions p
                                    INNER JOIN sys.indexes i ON p.object_id = i.object_id
                                                              AND p.index_id = i.index_id
                                    INNER JOIN sys.objects o ON p.object_id = o.object_id
                                    INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id
                                    INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
                                    INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id
                                    INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id
                                                              AND dds.destination_id = p.partition_number
                                    INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
                                    LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id
                                                              AND p.partition_number = rv.boundary_id
                           WHERE    i.index_id < 2
                                    AND o.object_id = OBJECT_ID(@TableName)
                                    AND au.type = 1
                                    AND fg.name <> 'TINY'
                         )
                SELECT  @LastPartitionCreated = TablePartitions.TableFileGroup ,
                        @CurrentRightEdgeValueActual = ( SELECT
                                                              MAX(TablePartitions.value)
                                                         FROM TablePartitions
                                                       )
                FROM    TablePartitions
                WHERE   TablePartitions.PartNum = ( SELECT  MAX(TablePartitions.PartNum)
                                                    FROM    TablePartitions
                                                  );


            PRINT @LastPartitionCreated;
			/* Is there one needed before the next frequency */
            SET @NeedNewPartition = 0;

			/* this is to make sure it is doing right I will remove once it is proven */
            PRINT @TableName + ' <= Table Name'; 
            PRINT @Frequency + ' <= Frequency'; 
            PRINT CAST(@FrequencyInterval AS VARCHAR(100))
                + ' <= FrequencyInterval';  
            PRINT @PartitionPattern + ' <= PartitionPattern'; 
            PRINT @FileNamePattern + ' <= FileNamePattern'; 
            PRINT @RightEdgePattern + ' <= RightEdgePattern'; 
            PRINT CAST(@CurrentRightEdgeValueActual AS VARCHAR(100))
                + ' <= CurrentRightEdgeValueActual';

			/* Caculate the RefDate */
            SELECT  @RefDate = PartitionCreate.CaculateRefDate(@Frequency,
                                                              @FrequencyInterval,
                                                              @Today);
               
            PRINT CONCAT(@RefDate, ' <= RefDate');

			/* Let create the new file group name */
            SET @FileGroupName = PartitionCreate.ReplacePatternStringForPartitions(@PartitionPattern,
                                                              @RefDate);
            PRINT CONCAT(@FileGroupName, ' <= FileGroupName');
			/* lets create the new right edge value. We will use this to see if we need a new partition */
            SET @NewRightEdgeValue = PartitionCreate.ReplacePatternStringForPartitions(@RightEdgePattern,
                                                              @RefDate);
            PRINT CONCAT(@NewRightEdgeValue, ' <= NewRightEdgeValue');

			/* is the new partition greater than the current one */
            IF ISNUMERIC(@NewRightEdgeValue) = 1
                BEGIN
                    IF @NewRightEdgeValue > CAST(@CurrentRightEdgeValueActual AS INT)
                        SET @NeedNewPartition = 1;
                END;
            ELSE
                IF ISDATE(@NewRightEdgeValue) = 1
                    IF @NewRightEdgeValue > CAST(CAST(@CurrentRightEdgeValueActual AS VARCHAR(100)) AS DATE)
                        SET @NeedNewPartition = 1;

			/* Check if this has a "+" or is for more that one frequency 
				so we can make sure this is not for a invalid intervial 
				e.g. if 2 months, 09_10 and 11_12 exists to don't create 10_11 */

            IF ( ( CHARINDEX('+', @PartitionFunctionName) > 0 )
                 OR @FrequencyInterval > 1
               )
                AND @NeedNewPartition = 1
                BEGIN
                    PRINT 'Check this out';
                    SET @TestInterval = @FrequencyInterval;
					/* We will create a test right edge value for the intervials that are skiped 
					   if they match the current one we will set to not create and break */
                    WHILE @TestInterval > 1
                        BEGIN
                            SET @TestInterval = @TestInterval - 1;
                            PRINT @TestInterval;

    						/* Caculate the TestRefDate */
                            SELECT  @TestRefDate = PartitionCreate.CaculateRefDate(@Frequency,
                                                              @FrequencyInterval
                                                              - @TestInterval,
                                                              @Today);
							/* Create a Right Edge Value from the test date*/           
                            SET @TestRightEdgeValue = PartitionCreate.ReplacePatternStringForPartitions(@RightEdgePattern,
                                                              @TestRefDate);
                            PRINT CONCAT(@TestRightEdgeValue,
                                         ' <= TestRightEdgeValue');
							/* if this is equal to an existing one then flip the create flag back to 0 */
                            IF ISNUMERIC(@TestRightEdgeValue) = 1
                                BEGIN
                                    IF @TestRightEdgeValue = CAST(@CurrentRightEdgeValueActual AS INT)
                                        BEGIN
                                            SET @NeedNewPartition = 0;
                                            PRINT 'break';
                                            BREAK;
                                        END;
                    
                                END;
                            ELSE
                                IF ISDATE(@TestRightEdgeValue) = 1
                                    IF @TestRightEdgeValue = CAST(CAST(@CurrentRightEdgeValueActual AS VARCHAR(100)) AS DATE)
                                        BEGIN
                                            SET @NeedNewPartition = 0;
                                            PRINT 'break';
                                            BREAK;
                                        END;
							/* If we are a multi year and there and the new edge is more than a year away lets wait */
                            IF @Frequency = 'Y'
                                AND @FrequencyInterval > 1
                                AND DATEDIFF(YEAR,
                                             CAST(CAST(@CurrentRightEdgeValueActual AS VARCHAR(100)) AS DATE),
                                             @NewRightEdgeValue) > 1
                                BEGIN
                                    SET @NeedNewPartition = 0;
                                    PRINT 'break';
                                    BREAK;
                                END;
                        END;
    
                END; 

            IF @NeedNewPartition = 1
                BEGIN
 
				/* Now that we know that we need another partition lets create it. */

                    SET @NewFileName = PartitionCreate.ReplacePatternStringForPartitions(@FileNamePattern,
                                                              @RefDate);

                    SET @NewFileAndPath = CONCAT(@DataFilePath, @NewFileName,
                                                 '.ndf');

					/* Create File Group */
					/* FileGroup and Partition Name is the same. */
                    SET @FileGroupName = PartitionCreate.ReplacePatternStringForPartitions(@PartitionPattern,
                                                              @RefDate);

                    SET @SQL = CONCAT('ALTER DATABASE ', @DatabaseName,
                                      ' ADD FILEGROUP ', @FileGroupName);

                    PRINT @SQL;
                    --EXEC sp_executesql @SQL;

					/* Create New File */
                    SET @SQL = CONCAT('ALTER DATABASE ', @DatabaseName,
                                      ' ADD FILE (');
                    SET @SQL = CONCAT(@SQL, 'NAME = ', @Quote, @NewFileName,
                                      @QuComSpa);
                    SET @SQL = CONCAT(@SQL, 'FILENAME = ', @Quote,
                                      @NewFileAndPath, @QuComSpa);
                    SET @SQL = CONCAT(@SQL, 'SIZE = ', @NewFileSize, @Comma,
                                      @Space);
                    SET @SQL = CONCAT(@SQL, 'MAXSIZE  = ', @Quote, 'UNLIMITED',
                                      @QuComSpa);
                    SET @SQL = CONCAT(@SQL, 'FILEGROWTH = ',
                                      @NewFileGrowthSetting, ') ');
                    SET @SQL = CONCAT(@SQL, 'TO FILEGROUP ', @FileGroupName);

                    PRINT @SQL;
                    --EXEC master.sys.sp_executesql @SQL;
        
					/* create new range for partition */
                    SET @SQL = CONCAT('ALTER PARTITION SCHEME ',
                                      @PartitionSchemeName, ' NEXT USED ',
                                      @FileGroupName);

                    PRINT @SQL;
                    --EXEC sp_executesql @SQL;

					/* Split partition range for new partion*/
                    SET @SQL = CONCAT('ALTER PARTITION FUNCTION ',
                                      @PartitionFunctionName,
                                      '() SPLIT RANGE (N', @Quote,
                                      @NewRightEdgeValue, @Quote, ')');

                    PRINT @SQL;
                    --EXEC sp_executesql @SQL;

                END; 

            PRINT '--------------------------------------------------------------------------------------------------------------------------------';

            FETCH NEXT FROM cTables INTO @TableName, @Frequency,
                @FrequencyInterval, @PartitionPattern, @PartitionFunctionName,
                @PartitionSchemeName, @FileNamePattern, @NewFileSize,
                @NewFileGrowthSetting, @DataFilePath, @RightEdgePattern; 

    
        END;

    CLOSE cTables;
    DEALLOCATE cTables;

