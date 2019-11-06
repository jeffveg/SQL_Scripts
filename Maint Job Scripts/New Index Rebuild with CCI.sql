
 USE [master];
GO
/****** Object:  StoredProcedure [dbo].[usp_rebuild_indexes_by_db]    Script Date: 1/20/2016 2:24:21 PM ******/
 SET ANSI_NULLS ON;
GO
 SET QUOTED_IDENTIFIER ON;
GO
 ALTER PROCEDURE [dbo].[usp_rebuild_indexes_by_db]
    @DBName NVARCHAR(128) -- Name of the db 
   ,@ReorgLimit TINYINT = 15 -- Minimum fragmentation % to use Reorg method 
   ,@RebuildLimit TINYINT = 30 -- Minimum fragmentation % to use Rebuild method 
   ,@PageLimit SMALLINT = 10 -- Minimum # of Pages before you worry about it 
   ,@CCIDeletedRows TINYINT = 25 -- Min % of deleted rows to rebuild clusterd columnstore index
   ,@SortInTempdb TINYINT = 1 -- 1 = Sort in tempdb option 
   ,@OnLine TINYINT = 1 -- 1 = Online Rebuild, Reorg is ignored 
   ,@ByPartition TINYINT = 1 -- 1 = Treat each partition separately 
   ,@LOBCompaction TINYINT = 1 -- 1 = Always do LOB compaction 
   ,@DoCIOnly TINYINT = 0 -- 1 = Only do Clustered indexes 
   ,@UpdateStats TINYINT = 1 -- 1 = Update the statistics after the Reorg process 
   ,@MaxDOP TINYINT = 0 -- 0 = Default so omit this from the statement 
   ,@ExcludedTables NVARCHAR(MAX) = '' -- Comma delimited list of tables (DB.schema.Table) to exclude from processing 
 AS
    SET NOCOUNT ON; 
/* 
Original Author: Andrew J. Kelly Solid Quality Mentors 
Enhancements and Modifications By: Timothy Ford, ford-IT.com

Note: This does not take into account off line file or file groups. This does not 
check to see if Indexed Views have LOB data types or if the index is Disabled. 

Please test this and all code fully before implementing into a live production enviorment. 
*/ 


    SET DEADLOCK_PRIORITY LOW; 

    BEGIN TRY 

        DECLARE @FullName NVARCHAR(400);
	--Fully-Qualified Name of table
        DECLARE @SQL NVARCHAR(1000);
	--Used for ad-hoc SQL statement builds
        DECLARE @Rebuild NVARCHAR(1000);
	--Used for ad-hoc build of ALTER INDEX... statement
        DECLARE @DBID SMALLINT;
	--Target database for index defragging
        DECLARE @Error INT;
  --Error counter variable
        DECLARE @TableName NVARCHAR(128);
		--Target table for index defragging
        DECLARE @SchemaName NVARCHAR(128);
	--Schema for target table
        DECLARE @HasLobs TINYINT;
	--Flag for determining if the index contains lob data, disqualifying for rebuild ONLINE
        DECLARE @object_id INT;
	--FROM sys.dm_db_index_physical_stat.object_id
        DECLARE @index_id INT;
	--FROM sys.dm_db_index_physical_stat.index_id
        DECLARE @partition_number INT;
		--FROM sys.dm_db_index_physical_stat.partition_number
        DECLARE @AvgFragPercent TINYINT;
		--FROM sys.dm_db_index_physical_stat.average_fragmentation_in_percent
        DECLARE @IndexName NVARCHAR(128);
	--FROM sys.sysindexes, is index name for target index
        DECLARE @Partitions INT;
	--Count of partitions from sys.partitions for target index
        DECLARE @Print NVARCHAR(1000);
	--Used to display status of process as a whole
        DECLARE @PartSQL NVARCHAR(600);
	--Used to construct SQL statement to return value for @Partitions variable
        DECLARE @ReOrgFlag TINYINT;
	--Used to determine if statistics are updated after the process completes.  This happens only if reorg since rebuild will automatically update stats.
        DECLARE @IndexTypeDesc NVARCHAR(60);
	--FROM sys.dm_db_index_physical_stat.index_type_desc
        DECLARE @IsClusterdColumstore TINYINT;
	-- Used to indicate this is a clustered columnstore index
        DECLARE @SQLEdition TINYINT;
		-- Used to see if the sql edition will support online rebuilds
        DECLARE @allow_page_locks TINYINT;
		-- used to see if the page lock setting will suport reorg
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


        SET @DBID = DB_ID(@DBName);
		
        SELECT  @SQLEdition = CONVERT(TINYINT, SERVERPROPERTY('EngineEdition'));

        BEGIN TRY
            DROP TABLE #FragLevels;
        END TRY 
        BEGIN CATCH 
        END CATCH;

        CREATE TABLE #FragLevels
            (
             [SchemaName] NVARCHAR(128) NULL
            ,[TableName] NVARCHAR(128) NULL
            ,[HasLOBs] TINYINT NULL
            ,IsClusterdColumstore TINYINT
            ,[ObjectID] [INT] NOT NULL
            ,[IndexID] [INT] NOT NULL
            ,[PartitionNumber] [INT] NOT NULL
            ,[AvgFragPercent] [TINYINT] NOT NULL
            ,[IndexName] NVARCHAR(128) NULL
            ,[IndexTypeDesc] NVARCHAR(60) NOT NULL
            ,AlowPageLocking TINYINT NULL
            ); 

-- Get the initial list of indexes and partitions to work on filtering out heaps and meeting the specified thresholds 
-- and any excluded fully qualified table names. 
        INSERT  INTO #FragLevels
                ([ObjectID]
                ,[IndexID]
                ,[PartitionNumber]
                ,[AvgFragPercent]
                ,[IndexTypeDesc]
                ,IsClusterdColumstore 
                )
        SELECT  a.[object_id]
               ,a.[index_id]
               ,a.[partition_number]
               ,CAST(a.[avg_fragmentation_in_percent] AS TINYINT) AS [AvgFragPercent]
               ,a.[index_type_desc]
               ,0
        FROM    sys.dm_db_index_physical_stats(@DBID, NULL, NULL, NULL,
                                               'LIMITED') AS a
        WHERE   a.[avg_fragmentation_in_percent] >= @ReorgLimit
                AND a.[page_count] >= @PageLimit
                AND ( a.[index_id] < CASE WHEN @DoCIOnly = 1 THEN 2
                                          ELSE 999999999
                                     END
                      AND a.[index_id] > 0
                    )
                AND a.[object_id] NOT IN (
                SELECT  ISNULL(OBJECT_ID(p.[ParsedValue]), 1)
                FROM    [dbo].[fn_split_inline_cte](@ExcludedTables, N',') AS p )
                AND a.[partition_number] < CASE WHEN @ByPartition = 1
                                                THEN 33000
                                                ELSE 2
                                           END; 


/* insert clusterd columnstore indexes */
        SET @SQL = N'
		INSERT INTO #FragLevels
				( ObjectID
				  ,IndexID
				  ,PartitionNumber
				  ,AvgFragPercent
				  ,IndexTypeDesc
				  ,IsClusterdColumstore
				 )
        SELECT  object_id
		       ,index_id
			   ,partition_number
			   ,CAST(sum(deleted_rows) AS FLOAT) / sum(total_rows) * 100.0
			   ,state_description
			   ,1
		FROM    ' + @DBName + N'.sys.column_store_row_groups
		WHERE   deleted_rows > 0
		        AND state = 3
		GROUP BY object_id
				,index_id
				,partition_number
				,state_description;'; -- we only want to look segments that are compressed

        BEGIN TRY
            EXEC(@SQL); 
        END TRY
        BEGIN CATCH
            PRINT 'May be an old version of SQL that doesnt support CCI';
        END CATCH;

        DELETE  #FragLevels
        WHERE   AvgFragPercent < @CCIDeletedRows
                AND IsClusterdColumstore = 1;


        CREATE INDEX [IX_#FragLevels_OBJECTID] ON #FragLevels([ObjectID]); 




-- Get the Schema and Table names for each 
        UPDATE  #FragLevels WITH ( TABLOCK )
        SET     [SchemaName] = OBJECT_SCHEMA_NAME([ObjectID], @DBID)
               ,[TableName] = OBJECT_NAME([ObjectID], @DBID); 

-- Determine if the index has a LOB datatype so we know if we can do online stuff or not 
        SET @SQL = N'UPDATE #FragLevels WITH (TABLOCK) SET [HasLOBs] = (SELECT TOP 1 CASE WHEN t.[lob_data_space_id] = 0 THEN 0 ELSE 1 END '
            + N' FROM [' + @DBName
            + N'].[sys].[tables] AS t WHERE t.[type] = ''U'' AND t.[object_id] = #FragLevels.[ObjectID])'; 

        EXEC(@SQL); 

-- Get the index name 
        SET @SQL = N'UPDATE #FragLevels SET [IndexName] = (SELECT TOP 1 t.[name] FROM ['
            + @DBName
            + N'].[sys].[indexes] AS t WHERE t.[object_id] = #FragLevels.[ObjectID] '
            + ' AND t.[index_id] = #FragLevels.[IndexID] )'; 


        EXEC(@SQL); 

-- get the page locking setting

        SET @SQL = N'UPDATE #FragLevels SET [AlowPageLocking] = (SELECT TOP 1 t.[allow_page_locks] FROM ['
            + @DBName
            + N'].[sys].[indexes] AS t WHERE t.[object_id] = #FragLevels.[ObjectID] '
            + ' AND t.[index_id] = #FragLevels.[IndexID] )'; 


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Present listing of indexes to be rebuilt or reorganized to the user
        SELECT  *
        FROM    #FragLevels; 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Get a list of the Indexes to Rebuild. 
        DECLARE curIndexes CURSOR STATIC
        FOR
            SELECT  [SchemaName]
                   ,[TableName]
                   ,[HasLOBs]
                   ,IsClusterdColumstore
                   ,[ObjectID]
                   ,[IndexID]
                   ,[PartitionNumber]
                   ,[AvgFragPercent]
                   ,[IndexName]
                   ,[IndexTypeDesc]
                   ,AlowPageLocking
            FROM    #FragLevels
            ORDER BY [ObjectID]
                   ,[IndexID] ASC; 

        OPEN curIndexes; 
        FETCH NEXT FROM curIndexes INTO @SchemaName, @TableName, @HasLobs,
            @IsClusterdColumstore, @object_id, @index_id, @partition_number,
            @AvgFragPercent, @IndexName, @IndexTypeDesc, @allow_page_locks; 

        WHILE ( @@fetch_status = 0 )
            BEGIN 

                SET @FullName = N'[' + @DBName + N'].[' + @SchemaName + N'].['
                    + @TableName + N']'; 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Rebuild all the eligable indexes on the table. If the table contains a LOB then we won't attempt to rebuild online. 
			-- If it has more than 1 partition we will do them by partition number unless @ByPartition parameter is turned off. 
                SET @PartSQL = N'SELECT @Partitions = COUNT(*) FROM ['
                    + @DBName
                    + N'].[sys].[partitions] WHERE [object_id] = @object_id AND [index_id] = @index_id'; 
                EXEC sp_executesql @PartSQL,
                    N'@Partitions INT OUTPUT, @object_id INT, @index_id INT',
                    @Partitions = @Partitions OUTPUT, @object_id = @object_id,
                    @index_id = @index_id; 

-- If this is a clusterd columnstore index rebuild with this statment ignore all other options
--ALTER INDEX CCSI_Person_Person REBUILD PARTITION = ALL



			-- If the frag level is below the minimum and is not a clustered columnstore just loop around 
			-- we take care of the clustered columnstore min rebuild above. 
                IF @AvgFragPercent < @ReorgLimit
                    AND @IsClusterdColumstore = 0
                    CONTINUE; 
			-- Dont reorg clustered columnstore indexes 
                IF @AvgFragPercent < @RebuildLimit
                    AND @IsClusterdColumstore = 0-- REORG  
                    AND @allow_page_locks = 1
                    BEGIN 
                        SET @Print = 'Reorganizing ' + @FullName + '('
                            + @IndexName + ')'; 
                        SET @Rebuild = N'ALTER INDEX [' + @IndexName
                            + N'] ON ' + @FullName + N' REORGANIZE'; 

                        IF @Partitions > 1
                            AND @ByPartition = 1
                            BEGIN 
                                SET @Rebuild = @Rebuild + N' PARTITION = '
                                    + CAST(@partition_number AS NVARCHAR(10)); 
                                SET @Print = @Print + ' PARTITION #: '
                                    + CAST(@partition_number AS VARCHAR(10)); 
                            END; 

                        SET @Rebuild = @Rebuild + ' WITH (,'; 
                        SET @ReOrgFlag = 1; 
                    END;
		 
                ELSE -- REBUILD & options 
                    BEGIN 
                        SET @Print = 'Rebuilding ' + @FullName + '('
                            + @IndexName + ')'; 
                        SET @Rebuild = N'ALTER INDEX [' + @IndexName
                            + N'] ON ' + @FullName + N' REBUILD'; 

                        IF @Partitions > 1
                            AND @ByPartition = 1
                            BEGIN 
                                SET @Rebuild = @Rebuild + N' PARTITION = '
                                    + CAST(@partition_number AS NVARCHAR(10)); 
                                SET @Print = @Print + ' PARTITION #: '
                                    + CAST(@partition_number AS VARCHAR(10)); 
                            END; 
                        SET @Rebuild = @Rebuild + ' WITH (,'; 

		
						-- If this is a clustered columnstor index skip non valid options
                        IF @IsClusterdColumstore = 0
                            BEGIN
                                
								-- ONLINE is only valid if there are NO LOBS and no Partitions 
								-- and is enterprise edition 
                                IF @Partitions < 2
                                    AND @OnLine = 1
                                    AND @HasLobs = 0
                                    AND @SQLEdition = 3
                                    BEGIN 
                                        SET @Rebuild = @Rebuild
                                            + N', ONLINE = ON '; 
                                    END; 

                                SET @Rebuild = @Rebuild
                                    + CASE WHEN @MaxDOP <> 0
                                           THEN N', MAXDOP = '
                                                + CAST(@MaxDOP AS NVARCHAR(2))
                                           ELSE N''
                                      END; 
				

                                SET @Rebuild = @Rebuild
                                    + CASE WHEN @SortInTempdb = 1
                                           THEN N', SORT_IN_TEMPDB = ON '
                                           ELSE N''
                                      END; 
                   
                            END;
                    END;
                SET @ReOrgFlag = 0; 
                        

                SET @Rebuild = @Rebuild
                    + CASE WHEN @LOBCompaction = 0
                           THEN N', LOB_COMPACTION = OFF '
                           ELSE N''
                      END; 
                SET @Rebuild = @Rebuild + N')'; 
                
                             
				-- Remove the WITH if there are no options 
                SET @Rebuild = REPLACE(@Rebuild, N'WITH (,)', N''); 

				-- Remove the extra comma if any 
                SET @Rebuild = REPLACE(@Rebuild, N'(,,', N'('); 
                   
                SET @Print = @Print + ' at: ' + CONVERT(VARCHAR(26), GETDATE(), 109)
                    + ' ***' + CHAR(13) + CHAR(10); 

			  --Print rebuild/reorg message
                PRINT @Print; 

		     -- Catch any individual errors so we can rebuild the others 
                BEGIN TRY 

					/* The low setting is causing the rebuild not to happen
					   because of a deadlock with the TupleMoverTask */
                    IF @IsClusterdColumstore = 1
                        SET DEADLOCK_PRIORITY HIGH;    

                    PRINT @Rebuild; 
                    EXEC(@Rebuild); 
                    
                    SET DEADLOCK_PRIORITY LOW; 
					
					--Now perform the statistics update process
					-- If we are doing a Reorg and the UpdateStats flag is on Update the Statistics for this index 
					-- Update the stats after the Reorg since they are not automatically done. Statistics on XML indexes can not be updated 
					-- XML or Invalid indexes will have a NULL IndexDepth property 
                    IF @UpdateStats = 1
                        AND @ReOrgFlag = 1
                        AND @IndexTypeDesc NOT LIKE N'%XML%'
                        BEGIN 
                            PRINT '*** Updating the stats for ' + @FullName
                                + '(' + @IndexName + ') at: '
                                + CONVERT(VARCHAR(26), GETDATE(), 109)
                                + ' ***' + CHAR(13) + CHAR(10); 

                            EXEC('UPDATE STATISTICS ' + @FullName + ' ([' + @IndexName + ']) WITH FULLSCAN' ); 
                        END; 

                END TRY 
                BEGIN CATCH 
                    SET @Error = 1; 
                    PRINT '------> There was an error rebuilding ' + @FullName
                        + ' (' + @IndexName + ')'; 
                    PRINT ''; 
                    SELECT  ERROR_NUMBER() AS ErrorNumber
                           ,ERROR_SEVERITY() AS ErrorSeverity
                           ,ERROR_STATE() AS ErrorState
                           ,ERROR_PROCEDURE() AS ErrorProcedure
                           ,ERROR_LINE() AS ErrorLine
                           ,ERROR_MESSAGE() AS ErrorMessage; 

                END CATCH; 

                FETCH NEXT FROM curIndexes INTO @SchemaName, @TableName,
                    @HasLobs, @IsClusterdColumstore, @object_id, @index_id,
                    @partition_number, @AvgFragPercent, @IndexName,
                    @IndexTypeDesc, @allow_page_locks;  

            END; 

        CLOSE curIndexes; 
        DEALLOCATE curIndexes; 

    END TRY 
    BEGIN CATCH 

        SELECT  ERROR_NUMBER() AS ErrorNumber
               ,ERROR_SEVERITY() AS ErrorSeverity
               ,ERROR_STATE() AS ErrorState
               ,ERROR_PROCEDURE() AS ErrorProcedure
               ,ERROR_LINE() AS ErrorLine
               ,ERROR_MESSAGE() AS ErrorMessage; 

		-- Raise an error so the sp that called this one catches it.; 
        PRINT ''; 
        RAISERROR('Error attempting to rebuild one or more indexes for: "%s"',16,1,@DBName); 

    END CATCH; 

    IF @Error = 1
        BEGIN 
            PRINT ''; 
            RAISERROR('There was one or more errors while attempting to rebuild the indexes for: "%s"',16,1,@DBName); 
            RETURN -1; 
        END; 




go
USE [msdb]
GO

/****** Object:  Job [DBA - Defrag Indexes]    Script Date: 1/22/2016 2:51:20 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 1/22/2016 2:51:20 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Defrag Indexes', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'ICESA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run index defrag proc]    Script Date: 1/22/2016 2:51:21 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run index defrag proc', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/* This is replacing the sp_foreach 
   it skips offline databaes and will
   check if this is an HA cluster and
   skip the read only replicas */
SET NOCOUNT OFF;
DECLARE @DBName NVARCHAR(255);
DECLARE @Statment NVARCHAR(4000);
DECLARE @Temp TABLE ( Name sysname );
 
 /* check to see if this is a HR Cluster */
IF SERVERPROPERTY(''IsHadrEnabled'') = 1
    BEGIN
        SET @Statment = ''
		SELECT  name
		FROM    master.sys.databases d
        LEFT JOIN sys.dm_hadr_availability_replica_states hars
            ON d.replica_id = hars.replica_id
		WHERE   name NOT IN (''''tempdb'''')
        AND state = 0
        AND source_database_id IS NULL
        AND ISNULL(hars.role, 1) = 1;'';
    END;
ELSE
    BEGIN
        SET @Statment = ''
		SELECT NAME
		FROM master.sys.databases
		WHERE NAME NOT IN (''''tempdb'''')
			AND STATE = 0
			AND source_database_id IS NULL;'';
    END;

INSERT  INTO @Temp
        (Name
        )
        EXEC master..sp_executesql @Statment;

DECLARE cReIndex CURSOR FAST_FORWARD READ_ONLY
FOR
    SELECT  Name
    FROM    @Temp
    ORDER BY Name;

OPEN cReIndex;

FETCH NEXT FROM cReIndex INTO @DBName;

WHILE @@FETCH_STATUS = 0
    BEGIN


        SET @Statment = ''usp_rebuild_indexes_by_db  @DBName = '''''' + @DBName
            + ''''''; '';
        PRINT ''Reindex for DB: '' + @DBName; 
        PRINT @Statment;
        EXEC master..sp_executesql @Statment;
        PRINT ''----------------------------------------------------------------------------------------------'';
        FETCH NEXT FROM cReIndex INTO @DBName;

    END;

CLOSE cReIndex; 
DEALLOCATE cReIndex;', 
		@database_name=N'master', 
		@output_file_name=N'S:\Microsoft SQL Server\DBA_Defrag.log', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=64, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20121116, 
		@active_end_date=99991231, 
		@active_start_time=210000, 
		@active_end_time=235959, 
		@schedule_uid=N'ebc5bd0b-a193-4480-adcd-95bc789fbf91'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO





