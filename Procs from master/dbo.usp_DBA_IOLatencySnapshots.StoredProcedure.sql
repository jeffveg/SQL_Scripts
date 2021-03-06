/****** Object:  StoredProcedure [dbo].[usp_DBA_IOLatencySnapshots]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_DBA_IOLatencySnapshots] (
	@action TINYINT = 0
)
AS 

/* TAKE INITIAL SNAPSHOT */
IF (@action = 0)
	BEGIN
		/* END OF DAY SNAPSHOT */
		IF OBJECT_ID('[dbo].[vfs_1]') IS NULL
			BEGIN
				CREATE TABLE [dbo].[vfs_1](
					[database_id] [SMALLINT] NOT NULL,
					[file_id] [SMALLINT] NOT NULL,
					[num_of_reads] [BIGINT] NOT NULL,
					[io_stall_read_ms] [BIGINT] NOT NULL,
					[num_of_writes] [BIGINT] NOT NULL,
					[io_stall_write_ms] [BIGINT] NOT NULL,
					[io_stall] [BIGINT] NOT NULL,
					[num_of_bytes_read] [BIGINT] NOT NULL,
					[num_of_bytes_written] [BIGINT] NOT NULL,
					[file_handle] [VARBINARY](8) NOT NULL,
					[auditdate] [DATETIME] NOT NULL
				) ON [PRIMARY];
			END
		ELSE 
			BEGIN
				TRUNCATE TABLE [dbo].[vfs_1];
			END

		INSERT INTO [dbo].[vfs_1]
		SELECT 
			[database_id]
			,[file_id]
			,[num_of_reads]
			,[io_stall_read_ms]
			,[num_of_writes]
			,[io_stall_write_ms]
			,[io_stall]
			,[num_of_bytes_read]
			,[num_of_bytes_written]
			,[file_handle]
			,getdate() as [auditdate]
		FROM [sys].[dm_io_virtual_file_stats] (NULL, NULL);
	END

/* TAKE END OF DAY SNAPSHOT */
IF (@action = 1)
	BEGIN
		/* END OF DAY SNAPSHOT */
		IF OBJECT_ID('[dbo].[vfs_2]') IS NULL
			BEGIN
				CREATE TABLE [dbo].[vfs_2](
					[database_id] [SMALLINT] NOT NULL,
					[file_id] [SMALLINT] NOT NULL,
					[num_of_reads] [BIGINT] NOT NULL,
					[io_stall_read_ms] [BIGINT] NOT NULL,
					[num_of_writes] [BIGINT] NOT NULL,
					[io_stall_write_ms] [BIGINT] NOT NULL,
					[io_stall] [BIGINT] NOT NULL,
					[num_of_bytes_read] [BIGINT] NOT NULL,
					[num_of_bytes_written] [BIGINT] NOT NULL,
					[file_handle] [VARBINARY](8) NOT NULL,
					[auditdate] [DATETIME] NOT NULL
				) ON [PRIMARY];
			END
		ELSE 
			BEGIN
				TRUNCATE TABLE [dbo].[vfs_2];
			END

		INSERT INTO [dbo].[vfs_2]
		SELECT 
			[database_id]
			,[file_id]
			,[num_of_reads]
			,[io_stall_read_ms]
			,[num_of_writes]
			,[io_stall_write_ms]
			,[io_stall]
			,[num_of_bytes_read]
			,[num_of_bytes_written]
			,[file_handle]
			,getdate() as [auditdate]
		FROM [sys].[dm_io_virtual_file_stats] (NULL, NULL);
	END

/* COMPARE AND RETURN RESULTS */
IF (@action = 2)
	BEGIN
		;WITH [DiffLatencies] AS
		 (SELECT
		 -- Files that weren't in the first snapshot
				 [ts2].[database_id]
				 ,[ts2].[file_id]
				 ,[ts2].[num_of_reads]
				 ,[ts2].[io_stall_read_ms]
				 ,[ts2].[num_of_writes]
				 ,[ts2].[io_stall_write_ms]
				 ,[ts2].[io_stall]
				 ,[ts2].[num_of_bytes_read]
				 ,[ts2].[num_of_bytes_written]
			 FROM [dbo].[vfs_2] AS [ts2]
			 LEFT OUTER JOIN [dbo].[vfs_1] AS [ts1] ON [ts2].[file_handle] = [ts1].[file_handle]
			 WHERE [ts1].[file_handle] IS NULL
		 UNION
		 SELECT
		 -- Diff of latencies in both snapshots
				 [ts2].[database_id]
				 ,[ts2].[file_id]
				 ,[ts2].[num_of_reads] - [ts1].[num_of_reads] AS [num_of_reads]
				 ,[ts2].[io_stall_read_ms] - [ts1].[io_stall_read_ms] AS [io_stall_read_ms]
				 ,[ts2].[num_of_writes] - [ts1].[num_of_writes] AS [num_of_writes]
				 ,[ts2].[io_stall_write_ms] - [ts1].[io_stall_write_ms] AS [io_stall_write_ms]
				 ,[ts2].[io_stall] - [ts1].[io_stall] AS [io_stall]
				 ,[ts2].[num_of_bytes_read] - [ts1].[num_of_bytes_read] AS [num_of_bytes_read]
				 ,[ts2].[num_of_bytes_written] - [ts1].[num_of_bytes_written] AS [num_of_bytes_written]
			 FROM [dbo].[vfs_2] AS [ts2]
			 LEFT OUTER JOIN [dbo].[vfs_1] AS [ts1] ON [ts2].[file_handle] = [ts1].[file_handle]
			 WHERE [ts1].[file_handle] IS NOT NULL)
		 SELECT
			 DB_NAME ([vfs].[database_id]) AS [DB]
			 ,LEFT ([mf].[physical_name], 2) AS [Drive]
			 ,[mf].[type_desc]
			 ,[num_of_reads] AS [Reads]
			 ,[num_of_writes] AS [Writes]
			 ,CASE WHEN [num_of_reads] = 0
				THEN 0 
				ELSE ([io_stall_read_ms] / [num_of_reads]) 
			END AS [ReadLatency(ms)]
			,CASE WHEN [num_of_writes] = 0
				THEN 0 
				ELSE ([io_stall_write_ms] / [num_of_writes]) 
			END AS [WriteLatency(ms)]
			/*
			 CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
				THEN 0 
				ELSE ([io_stall] / ([num_of_reads] + [num_of_writes])) 
			END AS [Latency]
			*/
			 ,CASE WHEN [num_of_reads] = 0
				THEN 0 
				ELSE ([num_of_bytes_read] / [num_of_reads]) 
			END AS [AvgPerRead(Bytes)]
			,CASE WHEN [num_of_writes] = 0
				THEN 0 
				ELSE ([num_of_bytes_written] / [num_of_writes]) 
			END AS [AvgPerWrite(Bytes)]
			 /*
			 ,CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
				THEN 0 
				ELSE (([num_of_bytes_read] + [num_of_bytes_written]) / ([num_of_reads] + [num_of_writes])) 
			END AS [AvgBPerTransfer]
			*/
			,[mf].[physical_name]
		 FROM [DiffLatencies] AS [vfs]
		 JOIN [sys].[master_files] AS [mf] ON [vfs].[database_id] = [mf].[database_id] AND [vfs].[file_id] = [mf].[file_id]
		 -- ORDER BY [ReadLatency(ms)] DESC
		 ORDER BY [WriteLatency(ms)] DESC
	END

/* ARCHIVE RESULTS */
IF (@action = 3)
	BEGIN
		IF OBJECT_ID('[dbo].[vfs_1_Archive]') IS NULL
			BEGIN
				CREATE TABLE [dbo].[vfs_1_Archive](
					[id] [INT] IDENTITY(1,1) CONSTRAINT [pk_vfs_1_Archive_id] PRIMARY KEY CLUSTERED NOT NULL,
					[database_id] [SMALLINT] NOT NULL,
					[file_id] [SMALLINT] NOT NULL,
					[num_of_reads] [BIGINT] NOT NULL,
					[io_stall_read_ms] [BIGINT] NOT NULL,
					[num_of_writes] [BIGINT] NOT NULL,
					[io_stall_write_ms] [BIGINT] NOT NULL,
					[io_stall] [BIGINT] NOT NULL,
					[num_of_bytes_read] [BIGINT] NOT NULL,
					[num_of_bytes_written] [BIGINT] NOT NULL,
					[file_handle] [VARBINARY](8) NOT NULL,
					[auditdate] [DATETIME] NOT NULL
				) ON [PRIMARY];

			END
		INSERT INTO [dbo].[vfs_1_Archive] (database_id, file_id, num_of_reads, io_stall_read_ms, num_of_writes, io_stall_write_ms, io_stall, num_of_bytes_read, num_of_bytes_written, file_handle, auditdate)
		SELECT * FROM [dbo].[vfs_1];

		IF OBJECT_ID('[dbo].[vfs_2_Archive]') IS NULL
			BEGIN
				CREATE TABLE [dbo].[vfs_2_Archive](
					[id] [INT] IDENTITY(1,1) CONSTRAINT [pk_vfs_1_Archive_id] PRIMARY KEY CLUSTERED NOT NULL,
					[database_id] [SMALLINT] NOT NULL,
					[file_id] [SMALLINT] NOT NULL,
					[num_of_reads] [BIGINT] NOT NULL,
					[io_stall_read_ms] [BIGINT] NOT NULL,
					[num_of_writes] [BIGINT] NOT NULL,
					[io_stall_write_ms] [BIGINT] NOT NULL,
					[io_stall] [BIGINT] NOT NULL,
					[num_of_bytes_read] [BIGINT] NOT NULL,
					[num_of_bytes_written] [BIGINT] NOT NULL,
					[file_handle] [VARBINARY](8) NOT NULL,
					[auditdate] [DATETIME] NOT NULL
				) ON [PRIMARY];

			END
		INSERT INTO [dbo].[vfs_2_Archive] (database_id, file_id, num_of_reads, io_stall_read_ms, num_of_writes, io_stall_write_ms, io_stall, num_of_bytes_read, num_of_bytes_written, file_handle, auditdate)
		SELECT * FROM [dbo].[vfs_2];
	END
GO
