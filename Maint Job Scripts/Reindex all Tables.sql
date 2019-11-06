
Declare  @Index_Name NVARCHAR(255)
		,@Schema_Name NVARCHAR(255)
		,@Table_Name NVARCHAR(255)
		,@Defrag_PCent DECIMAL(4,1)
		,@SQL NVARCHAR(4000)
		,@CRLF NCHAR(2)
		
SET @CRLF = CHAR(13) + CHAR(10) 

	
DECLARE cIndex CURSOR
READ_ONLY
FOR 
	SELECT /* defrag only when greater then 20% */
		 i.name IX_Name
		,s.name SC_Name
		,t.name TB_Name 
		,avg_fragmentation_in_percent
	FROM 
		sys.indexes i 
		join sys.tables t 
			ON i.object_id = t.object_id 
		join sys.schemas s 
			ON t.schema_id = s.schema_id
		join sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) ps
			ON  ps.OBJECT_ID = i.OBJECT_ID
				AND ps.index_id = i.index_id
	WHERE 
		i.type in (1,2) 
		and is_ms_shipped = 0
		and avg_fragmentation_in_percent > 20.0

DECLARE @name VARCHAR(40)
OPEN cIndex

FETCH NEXT FROM cIndex INTO @Index_Name, @Schema_Name, @Table_Name, @Defrag_PCent
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN

		PRINT @Index_Name + ' on Table ' + @Schema_Name + '.' + @Table_Name + ' Fragmation at ' + cast(@Defrag_PCent as nvarchar) + '%' 
		PRINT @CRLF
		
		SET @SQL = 'USE [' + DB_NAME() + '];' + @CRLF
		SET @SQL = @SQL + 'ALTER INDEX [' + @Index_Name + '] ON [' + @Schema_Name + '].[' + @Table_Name + ']' + @CRLF
		SET @SQL = @SQL + 'REORGANIZE WITH ( LOB_COMPACTION = ON );' + @CRLF
		--PRINT @SQL
		
		EXEC sp_executeSQL @SQL 
		
	END
	FETCH NEXT FROM cIndex INTO @Index_Name, @Schema_Name, @Table_Name, @Defrag_PCent 
END

CLOSE cIndex
DEALLOCATE cIndex
GO


-------------------------------------------------------------------------------------------------------------

For a list of db's


DECLARE @DBName NVARCHAR(255)
DECLARE @Statment1 NVARCHAR(4000)
DECLARE cReIndex CURSOR FAST_FORWARD READ_ONLY FOR
SELECT NAME
FROM master.sys.databases
WHERE NAME NOT IN ('tempdb')
	AND STATE = 0
	AND source_database_id IS NULL


/* -- If a HA cluster
DECLARE cReIndex CURSOR FAST_FORWARD READ_ONLY FOR
SELECT  name
FROM    master.sys.databases d
        LEFT JOIN sys.dm_hadr_availability_replica_states hars
            ON d.replica_id = hars.replica_id
WHERE   name NOT IN ('tempdb')
        AND state = 0
        AND source_database_id IS NULL
        AND ISNULL(hars.role, 1) = 1
*/

OPEN cReIndex

FETCH NEXT FROM cReIndex INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN


SET @Statment1 = 'use [' + @DBName + ']; 
Declare  @Index_Name NVARCHAR(255)
		,@Schema_Name NVARCHAR(255)
		,@Table_Name NVARCHAR(255)
		,@Defrag_PCent DECIMAL(4,1)
		,@SQL NVARCHAR(4000)
		,@CRLF NCHAR(2)
		
SET @CRLF = CHAR(13) + CHAR(10) 
	
DECLARE cIndex CURSOR
FOR 
	SELECT /* defrag only when greater then 20% */
		 i.name IX_Name
		,s.name SC_Name
		,t.name TB_Name 
		,avg_fragmentation_in_percent
	FROM 
		sys.indexes i 
		join sys.tables t 
			ON i.object_id = t.object_id 
		join sys.schemas s 
			ON t.schema_id = s.schema_id
		join sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) ps
			ON  ps.OBJECT_ID = i.OBJECT_ID
				AND ps.index_id = i.index_id
	WHERE 
		i.type in (1,2)
		and is_ms_shipped = 0
		and avg_fragmentation_in_percent > 20.0

DECLARE @name VARCHAR(40)
OPEN cIndex

FETCH NEXT FROM cIndex INTO @Index_Name, @Schema_Name, @Table_Name, @Defrag_PCent
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN

		PRINT @Index_Name + '' on Table '' + @Schema_Name + ''.'' + @Table_Name + '' Fragmation at '' + cast(@Defrag_PCent as nvarchar) + ''%'' 	
		SET @SQL = ''USE ['' + DB_NAME() + ''];'' + @CRLF
		SET @SQL = @SQL + ''ALTER INDEX ['' + @Index_Name + ''] ON ['' + @Schema_Name + ''].['' + @Table_Name + '']'' + @CRLF
		SET @SQL = @SQL + ''REORGANIZE WITH ( LOB_COMPACTION = ON );'' + @CRLF
		
		EXEC sp_executeSQL @SQL 
		
	END
	FETCH NEXT FROM cIndex INTO @Index_Name, @Schema_Name, @Table_Name, @Defrag_PCent 
END

CLOSE cIndex
DEALLOCATE cIndex
'

print 'Reindex for DB: ' + @DBName 
EXEC master..sp_executeSQL @Statment1
print '----------------------------------------------------------------------------------------------'
FETCH NEXT FROM cReIndex INTO @DBName

END

CLOSE cReIndex 
DEALLOCATE cReIndex 