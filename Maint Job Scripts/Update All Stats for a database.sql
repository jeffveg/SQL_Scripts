DECLARE @Index_Name NVARCHAR(255)
   ,@Schema_Name NVARCHAR(255)
   ,@Table_Name NVARCHAR(255)
   ,@Defrag_PCent DECIMAL(4, 1)
   ,@SQL NVARCHAR(4000)
   ,@CRLF NCHAR(2)
   ,@Msg NVARCHAR(200);
		
SET @CRLF = CHAR(13) + CHAR(10); 

	
DECLARE cStats CURSOR READ_ONLY
FOR
    SELECT DISTINCT
            s.name SchemaName
           ,OBJECT_NAME(st.[object_id]) AS TableName
    FROM    sys.stats st
    JOIN    sys.tables t
            ON st.object_id = t.object_id
    JOIN    sys.schemas s
            ON t.schema_id = s.schema_id
    WHERE   OBJECTPROPERTY(st.object_id, 'IsUserTable') = 1
            AND ( st.auto_created = 1
                  OR st.user_created = 1
                );

DECLARE @name VARCHAR(40);
OPEN cStats;

FETCH NEXT FROM cStats INTO @Schema_Name, @Table_Name;
WHILE ( @@fetch_status <> -1 )
    BEGIN
        IF ( @@fetch_status <> -2 )
            BEGIN

                SET @Msg = 'Updating Stats on table ' + @Schema_Name + '.'
                    + @Table_Name + @CRLF;

                RAISERROR (
			@Msg
			, 0
			, 0
			)WITH NOWAIT;
		
		
                SET @SQL = 'USE [' + DB_NAME() + '];' + @CRLF;
                SET @SQL = @SQL + 'UPDATE STATISTICS [' + @Schema_Name + '].['
                    + @Table_Name + ']' + @CRLF;
                SET @SQL = @SQL + 'WITH FULLSCAN;' + @CRLF;
		--PRINT @SQL
		
                EXEC sp_executesql @SQL; 
		
            END;
        FETCH NEXT FROM cStats INTO @Schema_Name, @Table_Name;
    END;

CLOSE cStats;
DEALLOCATE cStats;
GO
---------------------------------------------------------------------------------------------------

--For a list of db's


DECLARE @DBName NVARCHAR(255)
   ,@Statment1 NVARCHAR(4000)
   ,@Msg NVARCHAR(200);
DECLARE cUpdateStat CURSOR FAST_FORWARD READ_ONLY
FOR
    SELECT  name
    FROM    master.sys.databases
    WHERE   name IN ( 'icedw', 'icedw_working' );

OPEN cUpdateStat;

FETCH NEXT FROM cUpdateStat INTO @DBName;

WHILE @@FETCH_STATUS = 0
    BEGIN


        SET @Statment1 = 'use [' + @DBName
            + ']; 
Declare  @Index_Name NVARCHAR(255)
		,@Schema_Name NVARCHAR(255)
		,@Table_Name NVARCHAR(255)
		,@Defrag_PCent DECIMAL(4,1)
		,@SQL NVARCHAR(4000)
		,@CRLF NCHAR(2)
		,@Msg NVARCHAR(200)
		
SET @CRLF = CHAR(13) + CHAR(10) 

	
DECLARE cStats CURSOR
FOR 
	SELECT DISTINCT
		s.name SchemaName
		,OBJECT_NAME(st.[object_id]) AS TableName

	FROM 
		sys.stats st 
		join sys.tables t 
			ON st.object_id = t.object_id 
		join sys.schemas s 
			ON t.schema_id = s.schema_id
	WHERE 
		OBJECTPROPERTY(st.OBJECT_ID,''IsUserTable'') = 1
		AND (st.auto_created = 1 OR st.user_created = 1);

DECLARE @name VARCHAR(40)
OPEN cStats

FETCH NEXT FROM cStats INTO @Schema_Name, @Table_Name
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN

	SET @Msg = ''Updating Stats on table '' + @Schema_Name + ''.'' + @Table_Name

	RAISERROR (
			@Msg
			, 0
			, 0
			)WITH NOWAIT;
		
		
		SET @SQL = ''USE ['' + DB_NAME() + ''];'' + @CRLF
		SET @SQL = @SQL + ''UPDATE STATISTICS ['' + @Schema_Name + ''].['' + @Table_Name + '']'' + @CRLF
		SET @SQL = @SQL + ''WITH FULLSCAN;'' + @CRLF
				
		EXEC sp_executeSQL @SQL 
		
	END
	FETCH NEXT FROM cStats INTO @Schema_Name, @Table_Name
END

CLOSE cStats
DEALLOCATE cStats
';


        SET @Msg = 'Update Stats for DB: ' + @DBName; 

        RAISERROR (
			@Msg
			, 0
			, 0
			)WITH NOWAIT;

 
        EXEC sp_executesql @Statment1;
        PRINT '----------------------------------------------------------------------------------------------';
        FETCH NEXT FROM cUpdateStat INTO @DBName;

    END;

CLOSE cUpdateStat; 
DEALLOCATE cUpdateStat; 