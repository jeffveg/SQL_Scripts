/****** Object:  StoredProcedure [dbo].[sp_DBA_BackupToAzureLogHA2014]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_DBA_BackupToAzureLogHA2014]
	@storage [varchar](30),
	@container [varchar](100),
	@credential [varchar](65)
WITH EXECUTE AS CALLER
AS
DECLARE @BackUpPath NVARCHAR(1000);
--SET @BackUpPath = 'L:\Backups\'
    SET @BackUpPath = 'https://' + @storage + '.blob.core.windows.net/';

    DECLARE @DTStamp VARCHAR(28);
    DECLARE @Statment NVARCHAR(4000);
    DECLARE @DBName NVARCHAR(255);

    SET @DTStamp = CONVERT(VARCHAR(28), GETDATE(), 121);
    SET @DTStamp = REPLACE(@DTStamp, '-', '_');
    SET @DTStamp = REPLACE(@DTStamp, ' ', '_');
    SET @DTStamp = REPLACE(@DTStamp, ':', '');
    SET @DTStamp = REPLACE(@DTStamp, '.', '_');

--PRINT @DTStamp

    DECLARE cBackup CURSOR FAST_FORWARD READ_ONLY
    FOR
        SELECT  name
        FROM    master.sys.databases
        WHERE   name NOT IN ( 'tempdb' )
                AND recovery_model = 1
				AND [state] = 0
                AND database_id NOT IN (
                SELECT  st.database_id
                FROM    sys.dm_hadr_database_replica_states st
                JOIN    sys.dm_hadr_availability_replica_cluster_states nn
                        ON nn.replica_id = st.replica_id
                WHERE   st.is_primary_replica = 0
                        AND nn.replica_server_name = @@SERVERNAME );

    OPEN cBackup;

    FETCH NEXT FROM cBackup INTO @DBName;

    WHILE @@FETCH_STATUS = 0
        BEGIN

            SET @Statment = 'BACKUP LOG [' + @DBName + '] TO URL = '''
                + @BackUpPath + @container + '/' + @DBName + '_Log_'
                + @DTStamp + '.trn'' WITH CREDENTIAL =''' + @credential
                + ''', COMPRESSION, STATS = 5;';
            EXEC sp_executesql @Statment;
	--PRINT @Statment

            FETCH NEXT FROM cBackup INTO @DBName;

        END;

    CLOSE cBackup;
    DEALLOCATE cBackup;
GO
