/****** Object:  StoredProcedure [dbo].[usp_DBA_GetBackupsByDatabase]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_DBA_GetBackupsByDatabase] (
	@db VARCHAR(50) = NULL
)
AS
IF (@db IS NULL)
	BEGIN
		PRINT 'USAGE: ah ah ah, you didn''t say the magic word!'
		PRINT '--------------------------------------------------'
		PRINT 'EXEC [dbo].[usp_DBA_GetBackupsByDatabase] ''ICEDW'';'
	END
ELSE 
	BEGIN
		SELECT 
			[d].[name]
			,[b].[backup_finish_date]
			,[f].[physical_device_name]
			,CASE
				WHEN CHARINDEX('/',[f].[physical_device_name]) > 0 THEN RIGHT([f].[physical_device_name],CHARINDEX('/',REVERSE([f].[physical_device_name]))-1)
				ELSE [f].[physical_device_name]
			END  AS [backup_name]
			,CAST((([b].[backup_size] / 1024) / 1024) AS DECIMAL(9,2)) AS [SizeMB]
			,CASE [b].[type]
				WHEN 'L' THEN 'Log'
				WHEN 'I' THEN 'Diff'
				WHEN 'D' THEN 'Full'
			END AS [backup_type]
			,[b].[user_name]
		FROM [sys].[database_recovery_status] [s]
		JOIN [sys].[databases] [d] ON [s].[database_id] = [d].[database_id]
		JOIN [msdb].[dbo].[backupset] [b] ON [s].[database_guid] = [b].[database_guid]
		JOIN [msdb].[dbo].[backupmediafamily] [f] ON [b].[media_set_id] = [f].[media_set_id]
		WHERE ([d].[name] = @db)
		  AND ([b].[type] = 'L')
		  AND [b].[backup_set_id] > (SELECT MAX(backup_set_id) FROM [msdb].[dbo].[backupset] WHERE [type] = 'I' AND database_name = @db)

		UNION ALL

		SELECT 
			[d].[name]
			,[b].[backup_finish_date]
			,[f].[physical_device_name]
			,CASE
				WHEN CHARINDEX('/',[f].[physical_device_name]) > 0 THEN RIGHT([f].[physical_device_name],CHARINDEX('/',REVERSE([f].[physical_device_name]))-1)
				ELSE [f].[physical_device_name]
			END  AS [backup_name]
			,CAST((([b].[backup_size] / 1024) / 1024) AS DECIMAL(9,2)) AS [SizeMB]
			,CASE [b].[type]
				WHEN 'L' THEN 'Log'
				WHEN 'I' THEN 'Diff'
				WHEN 'D' THEN 'Full'
			END AS [backup_type]
			,[b].[user_name]
		FROM [sys].[database_recovery_status] [s]
		JOIN [sys].[databases] [d] ON [s].[database_id] = [d].[database_id]
		JOIN [msdb].[dbo].[backupset] [b] ON [s].[database_guid] = [b].[database_guid]
		JOIN [msdb].[dbo].[backupmediafamily] [f] ON [b].[media_set_id] = [f].[media_set_id]
		WHERE ([d].[name] = @db)
		  AND ([b].[type] = 'I')
		  AND [b].[backup_set_id] IN (SELECT TOP 1 MAX(backup_set_id) FROM [msdb].[dbo].[backupset] WHERE [type] = 'I' AND database_name = @db)

		UNION ALL

		SELECT 
			[d].[name]
			,[b].[backup_finish_date]
			,[f].[physical_device_name]
			,CASE
				WHEN CHARINDEX('/',[f].[physical_device_name]) > 0 THEN RIGHT([f].[physical_device_name],CHARINDEX('/',REVERSE([f].[physical_device_name]))-1)
				ELSE [f].[physical_device_name]
			END  AS [backup_name]
			,CAST((([b].[backup_size] / 1024) / 1024) AS DECIMAL(9,2)) AS [SizeMB]
			,CASE [b].[type]
				WHEN 'L' THEN 'Log'
				WHEN 'I' THEN 'Diff'
				WHEN 'D' THEN 'Full'
			END AS [backup_type]
			,[b].[user_name]
		FROM [sys].[database_recovery_status] [s]
		JOIN [sys].[databases] [d] ON [s].[database_id] = [d].[database_id]
		JOIN [msdb].[dbo].[backupset] [b] ON [s].[database_guid] = [b].[database_guid]
		JOIN [msdb].[dbo].[backupmediafamily] [f] ON [b].[media_set_id] = [f].[media_set_id]
		WHERE ([d].[name] = @db)
		  AND ([b].[type] = 'D')
		  AND [b].[backup_set_id] IN (SELECT MAX(backup_set_id) FROM [msdb].[dbo].[backupset] WHERE [type] = 'D' AND database_name = @db AND [is_copy_only] = 0)
		ORDER BY 2 DESC
	END
GO
