USE master; 
GO 


BEGIN TRY /* This is so I can run the script again and again */
    DROP PROCEDURE #MyForEach;
END TRY

BEGIN CATCH
END CATCH;
GO


CREATE PROCEDURE #MyForEach ( @CMD NVARCHAR(MAX) )
AS
    BEGIN

        DECLARE @dbs CURSOR
           ,@cmd2Run NVARCHAR(MAX)
           ,@db NVARCHAR(128)
           ,@sp NVARCHAR(255);
        SET @dbs = CURSOR STATIC
			FOR
			SELECT name
			FROM sys.databases
			WHERE state = 0;/* State 0 = online */

        OPEN @dbs;

        WHILE ( 1 = 1 )
            BEGIN
                FETCH @dbs INTO @db;

                IF @@FETCH_STATUS <> 0
                    BREAK;

                SET @cmd2Run = REPLACE(@CMD, '?', @db);
                SET @sp = QUOTENAME(@db) + N'.sys.sp_executesql';

                BEGIN TRY
                    EXEC @sp @cmd2Run;
                END TRY

                BEGIN CATCH
                END CATCH;
            END;
    END;
                
GO

       
	           DECLARE @Results TABLE
            (
             DatabaseName sysname
            ,SchemaName sysname
            ,TableName sysname
            ,Query NVARCHAR(MAX)
            );

	   
DECLARE @SQL VARCHAR(3000);

SET @SQL = '
        SET NOCOUNT ON;

        DECLARE @Tmp TABLE
            (
             SchemaName sysname
            ,TableName sysname
            ,ColumnName sysname
            );
        DECLARE @Results TABLE
            (
             DatabaseName sysname
            ,SchemaName sysname
            ,TableName sysname
            ,Query NVARCHAR(MAX)
            );
        DECLARE @ColumnName sysname; 
        DECLARE @SelectList NVARCHAR(MAX);
        DECLARE @TableName sysname;
        DECLARE @SchemaName sysname;

        INSERT  INTO @Tmp
        SELECT  SCHEMA_NAME(o.schema_id)
               ,o.name
               ,c.name
        FROM    syscolumns c
        JOIN    sys.objects o
                ON o.object_id = c.id
        WHERE   o.type = ''U''
                AND ( c.name LIKE ''%CC%''
                      OR c.name LIKE ''%Credit%''
                      OR c.name LIKE ''%Card%''
                    );

        DECLARE cQueryBuild CURSOR FAST_FORWARD READ_ONLY
        FOR
            SELECT  SchemaName
                   ,TableName
            FROM    @Tmp
            GROUP BY SchemaName
                   ,TableName
            ORDER BY SchemaName
                   ,TableName;

        OPEN cQueryBuild;

        FETCH NEXT FROM cQueryBuild INTO @SchemaName, @TableName;

        WHILE @@FETCH_STATUS = 0
            BEGIN
			PRINT CONCAT(''Checking '', @TableName)
                SET @SelectList = NULL;

/* Create a slash demimited list of apps for the current server */
                SELECT  @SelectList = COALESCE(@SelectList + '','', '''')
                        + ColumnName
                FROM    @Tmp
                WHERE   TableName = @TableName
                        AND @SchemaName = SchemaName;

/* insert list in to output table*/        
                INSERT  INTO @Results
                VALUES  ( DB_NAME(), @SchemaName, @TableName,
                          CONCAT(''Select top 10 '', @SelectList, '' FROM '',
                                 DB_NAME(), ''.'', @SchemaName, ''.'', @TableName) );

                FETCH NEXT FROM cQueryBuild INTO @SchemaName, @TableName;

            END;

        CLOSE cQueryBuild;
        DEALLOCATE cQueryBuild;
        IF ( SELECT COUNT(*)
             FROM   @Results
           ) > 0
            SELECT  *
            FROM    @Results;
			'
INSERT INTO @Results
        ( DatabaseName
        ,SchemaName
        ,TableName
        ,Query
        )
EXEC #MyForEach @SQL;

SELECT * FROM @Results