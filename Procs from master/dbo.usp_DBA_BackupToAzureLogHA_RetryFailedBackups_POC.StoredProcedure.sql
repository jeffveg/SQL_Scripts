/****** Object:  StoredProcedure [dbo].[usp_DBA_BackupToAzureLogHA_RetryFailedBackups_POC]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_DBA_BackupToAzureLogHA_RetryFailedBackups_POC]
	@storage [varchar](30),
	@container [varchar](100),
	@credential [varchar](65),
	/* ADDING PARAM WITH OVERRIDE FOR FAILED BACKUPS 0-zero NORMAL AND 1-one FOR FAILED BACKUPS */
	@failedBackups [bit] = 0,
	@retry [bit] = 1,
	@bktype [varchar](10) = 'Log',
	@alert [BIT] = 0
WITH EXECUTE AS CALLER
AS
SET NOCOUNT ON;
DECLARE @BackUpPath NVARCHAR(1000)
--SET @BackUpPath = 'L:\Backups\'
    SET @BackUpPath = 'https://' + @storage + '.blob.core.windows.net/';

    DECLARE @DTStamp VARCHAR(28);
    DECLARE @Statment NVARCHAR(4000);
    DECLARE @DBName NVARCHAR(255);
	DECLARE @srv VARCHAR(50), @sub VARCHAR(256)
	SET @srv = @@SERVERNAME;
    SET @DTStamp = CONVERT(VARCHAR(28), GETDATE(), 121);
    SET @DTStamp = REPLACE(@DTStamp, '-', '_');
    SET @DTStamp = REPLACE(@DTStamp, ' ', '_');
    SET @DTStamp = REPLACE(@DTStamp, ':', '');
    SET @DTStamp = REPLACE(@DTStamp, '.', '_');

--PRINT @DTStamp

IF (@failedBackups = 0)
	
	/* BUILD STANDARD BACKUP LIST */
	BEGIN
		IF OBJECT_ID('[dbo].[FailedBackups]') IS NOT NULL
			BEGIN
				/* DELETE FAILEDBACKUPS TABLE PRIOR TO NORMAL PROCESSING BY BACKUPTYPE */
				DELETE [dbo].[FailedBackups] WHERE ([BackupType] = @bktype);
			END
		ELSE
			BEGIN
				CREATE TABLE [dbo].[FailedBackups] (
					[Database] VARCHAR(50)
					,[BackupType] VARCHAR(10)
					,[CreateDate] DATETIME NOT NULL CONSTRAINT [DF_FailedBackups_CreateDate] DEFAULT(GETDATE())
					,[Error] VARCHAR(1500) NULL
					,[RetryDate] DATETIME NULL
					,[RetryError] VARCHAR(1500) NULL
				);
			END

		DECLARE cBackup CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT  name
        FROM    master.sys.databases
        WHERE   name NOT IN ( 'tempdb' )
				AND [state] = 0
				AND [recovery_model] = 1
                AND database_id NOT IN (
                SELECT  st.database_id
                FROM    sys.dm_hadr_database_replica_states st
                JOIN    sys.dm_hadr_availability_replica_cluster_states nn
                        ON nn.replica_id = st.replica_id
                WHERE   st.is_primary_replica = 0
                        AND nn.replica_server_name = @srv )
				ORDER BY 1;
	END
ELSE 
	/* BUILD FAILED BACKUP LIST */
	BEGIN
		DECLARE cBackup CURSOR FAST_FORWARD READ_ONLY FOR
		SELECT [Database] FROM [dbo].[FailedBackups] WHERE ([BackupType] = @bktype) ORDER BY 1
	END

OPEN cBackup;
FETCH NEXT FROM cBackup INTO @DBName;

WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Statment = 'BACKUP LOG [' + @DBName + '] TO URL = '''
            + @BackUpPath + @container + '/' + @DBName + '_LOG_'
            + @DTStamp + '.trn'' WITH CREDENTIAL =''' + @credential
            + ''', COMPRESSION, STATS = 5;';
			PRINT @Statment;
			BEGIN TRY
				EXEC sp_executeSQL @Statment;

				IF (@failedBackups = 1 AND ERROR_NUMBER() IS NULL)
					BEGIN
						DELETE FROM [dbo].[FailedBackups] WHERE ([Database] = @DBName AND [BackupType] = @bktype);

						IF (@alert = 1)
							BEGIN
								SET @sub = @srv + ': Successful (' + @bktype + ') Retry Backup of (' + @DBName + ')';

								EXEC [msdb].[dbo].[sp_send_dbmail] 
									@profile_name = @srv,
									@recipients = 'sqladmins@iceenterprise.com',
									@subject = @sub,
									@from_address = 'Database Admins<databaseadmins@iceenterprise.com>';
							END
					END

			END TRY

			BEGIN CATCH
				IF NOT EXISTS (SELECT [Database] FROM [dbo].[FailedBackups] WHERE ([Database] = @DBName AND [BackupType] = @bktype))
					BEGIN
						/* LOAD DATABASE NAME THAT FAILED TO BACKUP INTO THE FailedBackups TABLE FOR PROCESSING LATER */
						INSERT INTO [dbo].[FailedBackups] ([Database], [BackupType], [Error]) VALUES (@DBName, @bktype, ERROR_MESSAGE());

						--SET @sub = @srv + ': Failed (' + @bktype + ') Backup of (' + @DBName + '). Added for retry!';

						--EXEC [msdb].[dbo].[sp_send_dbmail] 
						--	@profile_name = @srv,
						--	@recipients = 'sqladmins@iceenterprise.com',
						--	@subject = @sub,
						--	@from_address = 'Database Admins<databaseadmins@iceenterprise.com>';
					END
				ELSE
					BEGIN
						UPDATE [dbo].[FailedBackups] SET [RetryDate] = GETDATE(), [RetryError] = ERROR_MESSAGE() WHERE ([Database] = @DBName AND [BackupType] = @bktype);
					END
			END CATCH

        FETCH NEXT FROM cBackup INTO @DBName;

    END;

CLOSE cBackup;
DEALLOCATE cBackup;

/* CHECK FOR FAILED BACKUPS */
IF ((SELECT COUNT(*) FROM [dbo].[FailedBackups] WHERE BackupType = @bktype) > 0 AND @retry = 1)
	BEGIN

		IF (@alert = 1)
			BEGIN
				SET @sub = @srv + ': Starting (' + @bktype + ') Retry Backup of (' + @DBName + ')';

				EXEC [msdb].[dbo].[sp_send_dbmail] 
					@profile_name = @srv,
					@recipients = 'sqladmins@iceenterprise.com',
					@subject = @sub,
					@from_address = 'Database Admins<databaseadmins@iceenterprise.com>';
			END

		/* RUN FAILED BACKUP PROCESS ONCE - IN ORDER TO AVOID A LOOP SHOULD THERE BE AN ISSUE COMMUNICATING WITH AZURE */
		EXEC [dbo].[usp_DBA_BackupToAzureLogHA_RetryFailedBackups_POC] @storage, @container, @credential, @failedBackups = 1, @retry = 0;
		
	END
GO
