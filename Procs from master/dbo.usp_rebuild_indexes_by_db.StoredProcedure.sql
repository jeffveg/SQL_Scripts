/****** Object:  StoredProcedure [dbo].[usp_rebuild_indexes_by_db]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_rebuild_indexes_by_db] 
@DBName NVARCHAR(128) -- Name of the db 
, @ReorgLimit TINYINT = 15 -- Minimum fragmentation % to use Reorg method 
, @RebuildLimit TINYINT = 30 -- Minimum fragmentation % to use Rebuild method 
, @PageLimit SMALLINT = 10 -- Minimum # of Pages before you worry about it 
, @SortInTempdb TINYINT = 1 -- 1 = Sort in tempdb option 
, @OnLine TINYINT = 1 -- 1 = Online Rebuild, Reorg is ignored 
, @ByPartition TINYINT = 1 -- 1 = Treat each partition separately 
, @LOBCompaction TINYINT = 1 -- 1 = Always do LOB compaction 
, @DoCIOnly TINYINT = 0 -- 1 = Only do Clustered indexes 
, @UpdateStats TINYINT = 1 -- 1 = Update the statistics after the Reorg process 
, @MaxDOP TINYINT = 0 -- 0 = Default so omit this from the statement 
, @ExcludedTables NVARCHAR(MAX) = '' -- Comma delimited list of tables (DB.schema.Table) to exclude from processing 

AS 

SET NOCOUNT ON ; 
/* 
Original Author: Andrew J. Kelly Solid Quality Mentors 
Enhancements and Modifications By: Timothy Ford, ford-IT.com

Note: This does not take into account off line file or file groups. This does not 
check to see if Indexed Views have LOB data types or if the index is Disabled. 

Please test this and all code fully before implementing into a live production enviorment. 
*/ 

SET DEADLOCK_PRIORITY LOW ; 

BEGIN TRY 
--VARIABLE DECLARATIONS----------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @FullName nvarchar(400)	--Fully-Qualified Name of table
DECLARE @SQL nvarchar(1000)	--Used for ad-hoc SQL statement builds
DECLARE @Rebuild nvarchar(1000)	--Used for ad-hoc build of ALTER INDEX... statement
DECLARE @DBID smallint	--Target database for index defragging
DECLARE @Error int  --Error counter variable
DECLARE @TableName nvarchar(128)		--Target table for index defragging
DECLARE @SchemaName nvarchar(128)	--Schema for target table
DECLARE @HasLobs tinyint	--Flag for determining if the index contains lob data, disqualifying for rebuild ONLINE
DECLARE @object_id int	--FROM sys.dm_db_index_physical_stat.object_id
DECLARE @index_id int	--FROM sys.dm_db_index_physical_stat.index_id
DECLARE @partition_number int		--FROM sys.dm_db_index_physical_stat.partition_number
DECLARE @AvgFragPercent tinyint		--FROM sys.dm_db_index_physical_stat.average_fragmentation_in_percent
DECLARE @IndexName nvarchar(128)	--FROM sys.sysindexes, is index name for target index
DECLARE @Partitions int	--Count of partitions from sys.partitions for target index
DECLARE @Print nvarchar(1000)	--Used to display status of process as a whole
DECLARE @PartSQL nvarchar(600)	--Used to construct SQL statement to return value for @Partitions variable
DECLARE @ReOrgFlag tinyint	--Used to determine if statistics are updated after the process completes.  This happens only if reorg since rebuild will automatically update stats.
DECLARE @IndexTypeDesc nvarchar(60)	--FROM sys.dm_db_index_physical_stat.index_type_desc
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Determine if option to perform online rebuild is allowed, based upon SQL Server edition
IF SERVERPROPERTY('EngineEdition') <> 3 -- Enterprise, EE EVAL or Developer 
SET @OnLine = 0 ; 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Resolve @DBName parameter to the dbid for the target database
SET @DBID = DB_ID(@DBName) ; 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Load applicable values into temp table for processing from sys.dm_db_index_physical_stats

CREATE TABLE #FragLevels ( 
[SchemaName] NVARCHAR(128) NULL, [TableName] NVARCHAR(128) NULL, [HasLOBs] TINYINT NULL, 
[ObjectID] [int] NOT NULL, [IndexID] [int] NOT NULL, [PartitionNumber] [int] NOT NULL, 
[AvgFragPercent] [tinyint] NOT NULL, [IndexName] NVARCHAR(128) NULL, [IndexTypeDesc] NVARCHAR(60) NOT NULL ) ; 

-- Get the initial list of indexes and partitions to work on filtering out heaps and meeting the specified thresholds 
-- and any excluded fully qualified table names. 
INSERT INTO #FragLevels ([ObjectID], [IndexID], [PartitionNumber], [AvgFragPercent], [IndexTypeDesc]) 
SELECT 
	a.[object_id], 
	a.[index_id], 
	a.[partition_number], 
	CAST(a.[avg_fragmentation_in_percent] AS TINYINT) AS [AvgFragPercent], 
	a.[index_type_desc] 
FROM sys.dm_db_index_physical_stats(@DBID, NULL, NULL, NULL , 'LIMITED') AS a 
WHERE 
	a.[avg_fragmentation_in_percent] >= @ReorgLimit 
	AND a.[page_count] >= @PageLimit
	AND 
		(
		a.[index_id] < 
			CASE 
				WHEN @DoCIOnly = 1 THEN 2 
				ELSE 999999999 
			END 
		AND a.[index_id] >0
		) 
	AND a.[object_id] NOT IN 
		(
		SELECT ISNULL(OBJECT_ID(p.[ParsedValue]),1) 
		FROM [dbo].[fn_split_inline_cte](@ExcludedTables,N',') AS p
		) 
	AND a.[partition_number] < 
		CASE 
			WHEN @ByPartition = 1 THEN 33000 
			ELSE 2 
		END ; 

-- Create an index to make some of the updates & lookups faster 
CREATE INDEX [IX_#FragLevels_OBJECTID] ON #FragLevels([ObjectID]) ; 

-- Get the Schema and Table names for each 
UPDATE #FragLevels WITH (TABLOCK) 
SET 
	[SchemaName] = OBJECT_SCHEMA_NAME([ObjectID],@DBID), 
	[TableName] = OBJECT_NAME([ObjectID],@DBID) ; 

-- Determine if the index has a LOB datatype so we know if we can do online stuff or not 
SET @SQL = N'UPDATE #FragLevels WITH (TABLOCK) SET [HasLOBs] = (SELECT TOP 1 CASE WHEN t.[lob_data_space_id] = 0 THEN 0 ELSE 1 END ' + 
N' FROM [' + @DBName + N'].[sys].[tables] AS t WHERE t.[type] = ''U'' AND t.[object_id] = #FragLevels.[ObjectID])' ; 

EXEC(@SQL) ; 

-- Get the index name 
SET @SQL = N'UPDATE #FragLevels SET [IndexName] = (SELECT TOP 1 t.[name] FROM [' + @DBName + N'].[sys].[indexes] AS t WHERE t.[object_id] = #FragLevels.[ObjectID] ' + 
' AND t.[index_id] = #FragLevels.[IndexID] )' ; 

EXEC(@SQL) ; 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Present listing of indexes to be rebuilt or reorganized to the user
SELECT * FROM #FragLevels 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Get a list of the Indexes to Rebuild. 
DECLARE curIndexes CURSOR STATIC 
FOR 
SELECT [SchemaName], [TableName], [HasLOBs], [ObjectID], [IndexID], [PartitionNumber], [AvgFragPercent], [IndexName], [IndexTypeDesc] 
FROM #FragLevels ORDER BY [ObjectID], [IndexID] ASC ; 

OPEN curIndexes ; 
FETCH NEXT FROM curIndexes INTO @SchemaName, @TableName, @HasLobs, @object_id, @index_id, @partition_number, @AvgFragPercent, @IndexName, @IndexTypeDesc ; 

WHILE (@@fetch_status = 0) 
BEGIN 

SET @FullName = N'[' + @DBName + N'].[' + @SchemaName + N'].[' + @TableName + N']' ; 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Rebuild all the eligable indexes on the table. If the table contains a LOB then we won't attempt to rebuild online. 
-- If it has more than 1 partition we will do them by partition number unless @ByPartition parameter is turned off. 
SET @PartSQL = N'SELECT @Partitions = COUNT(*) FROM [' + @DBName + N'].[sys].[partitions] WHERE [object_id] = @object_id AND [index_id] = @index_id' 
EXEC sp_executesql @PartSQL, N'@Partitions INT OUTPUT, @object_id INT, @index_id INT', @Partitions = @Partitions OUTPUT, @object_id = @object_id, @index_id = @index_id ; 

-- If the frag level is below the minimum just loop around 
IF @AvgFragPercent < @ReorgLimit 
CONTINUE 

IF @AvgFragPercent < @RebuildLimit -- REORG 
	BEGIN 
		SET @Print = 'Reorganizing ' + @FullName + '(' + @IndexName + ')' ; 
		SET @Rebuild = N'ALTER INDEX [' + @IndexName + N'] ON ' + @FullName + N' REORGANIZE' ; 

		IF @Partitions > 1 AND @ByPartition = 1 
			BEGIN 
				SET @Rebuild = @Rebuild + N' PARTITION = ' + CAST(@partition_number AS NVARCHAR(10)) ; 
				SET @Print = @Print + ' PARTITION #: ' + CAST(@partition_number AS VARCHAR(10)) ; 
			END ; 

		SET @Rebuild = @Rebuild + ' WITH (,' ; 
		SET @ReOrgFlag = 1 
	END
		 
ELSE -- REBUILD & options 
	BEGIN 
		SET @Print = 'Rebuilding ' + @FullName + '(' + @IndexName + ')' ; 
		SET @Rebuild = N'ALTER INDEX [' + @IndexName + N'] ON ' + @FullName + N' REBUILD' ; 

		IF @Partitions > 1 AND @ByPartition = 1 
			BEGIN 
				SET @Rebuild = @Rebuild + N' PARTITION = ' + CAST(@partition_number AS NVARCHAR(10)) ; 
				SET @Print = @Print + ' PARTITION #: ' + CAST(@partition_number AS VARCHAR(10)) ; 
			END ; 

		SET @Rebuild = @Rebuild + ' WITH (,' ; 

		-- ONLINE is only valid if there are NO LOBS and no Partitions 
		IF @Partitions < 2 AND @OnLine = 1 AND @HasLobs = 0 
			BEGIN 
				SET @Rebuild = @Rebuild + N', ONLINE = ON ' ; 
			END ; 

		SET @Rebuild = @Rebuild + CASE WHEN @MaxDOP <> 0 THEN N', MAXDOP = ' + CAST(@MaxDOP AS NVARCHAR(2)) ELSE N'' END ; 
		SET @Rebuild = @Rebuild + CASE WHEN @SortInTempdb = 1 THEN N', SORT_IN_TEMPDB = ON ' ELSE N'' END ; 
		SET @ReOrgFlag = 0 
	END ; 

SET @Rebuild = @Rebuild + CASE WHEN @LOBCompaction = 0 THEN N', LOB_COMPACTION = OFF ' ELSE N'' END ; 
SET @Rebuild = @Rebuild + N')' ; 

-- Remove the WITH if there are no options 
SET @Rebuild = REPLACE(@Rebuild,N'WITH (,)',N'') ; 

-- Remove the extra comma if any 
SET @Rebuild = REPLACE(@Rebuild,N'(,,',N'(') ; 

SET @Print = @Print + ' at: ' + CONVERT(VARCHAR(26),GETDATE(),109) + ' ***' + CHAR(13) + CHAR(10) ; 

--Print rebuild/reorg message
PRINT @Print 

-- Catch any individual errors so we can rebuild the others 
BEGIN TRY 

EXEC(@Rebuild); 
PRINT @Rebuild ; 
--Now perform the statistics update process
-- If we are doing a Reorg and the UpdateStats flag is on Update the Statistics for this index 
-- Update the stats after the Reorg since they are not automatically done. Statistics on XML indexes can not be updated 
-- XML or Invalid indexes will have a NULL IndexDepth property 
IF @UpdateStats = 1 AND @ReOrgFlag = 1 AND @IndexTypeDesc NOT LIKE N'%XML%' 
	BEGIN 
		PRINT '*** Updating the stats for ' + @FullName + '(' + @IndexName + ') at: ' + CONVERT(VARCHAR(26),GETDATE(),109) + ' ***' + CHAR(13) + CHAR(10) ; 

		EXEC('UPDATE STATISTICS ' + @FullName + ' ([' + @IndexName + ']) WITH FULLSCAN' ) 
	END ; 

END TRY 
BEGIN CATCH 
SET @Error = 1 ; 
PRINT '------> There was an error rebuilding ' + @FullName + ' (' + @IndexName + ')' ; 
Print ''; 
SELECT 
ERROR_NUMBER() AS ErrorNumber, 
ERROR_SEVERITY() AS ErrorSeverity, 
ERROR_STATE() AS ErrorState, 
ERROR_PROCEDURE() AS ErrorProcedure, 
ERROR_LINE() AS ErrorLine, 
ERROR_MESSAGE() AS ErrorMessage; 

END CATCH ; 

FETCH NEXT FROM curIndexes INTO @SchemaName, @TableName, @HasLobs, @object_id, @index_id, @partition_number, @AvgFragPercent, @IndexName, @IndexTypeDesc ; 

END ; 

CLOSE curIndexes ; 
DEALLOCATE curIndexes ; 

END TRY 
BEGIN CATCH 

SELECT 
ERROR_NUMBER() AS ErrorNumber, 
ERROR_SEVERITY() AS ErrorSeverity, 
ERROR_STATE() AS ErrorState, 
ERROR_PROCEDURE() AS ErrorProcedure, 
ERROR_LINE() AS ErrorLine, 
ERROR_MESSAGE() AS ErrorMessage; 

-- Raise an error so the sp that called this one catches it.; 
PRINT '' ; 
RAISERROR('Error attempting to rebuild one or more indexes for: "%s"',16,1,@DBName) ; 

END CATCH ; 

IF @Error = 1 
BEGIN 
PRINT '' ; 
RAISERROR('There was one or more errors while attempting to rebuild the indexes for: "%s"',16,1,@DBName) ; 
RETURN -1 ; 
END ; 
GO
