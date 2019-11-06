EXEC [dbo].[sp_DBA_BackupToAzureLog] 'sqlbackups01','dba01','SQL_Azure_Backup'


DROP CREDENTIAL SQL_Azure_Backup;
CREATE CREDENTIAL SQL_Azure_Backup WITH IDENTITY = 'sqlbackups01'
,SECRET = '' ;


DROP CREDENTIAL SQL_Azure_Backup_Test
CREATE CREDENTIAL SQL_Azure_Backup_Test WITH IDENTITY = 'icetestsqlback'
,SECRET = '' ;

BACKUP DATABASE master
TO URL = 'https://icetestsqlback.blob.core.windows.net/devovs/Master4.bak'
      WITH CREDENTIAL = 'SQL_Azure_Backup_Test'
     ,COMPRESSION
     ,STATS = 5;
GO
DBCC TRACEON (3051,-1)
BACKUP database master
TO URL = 'https://sqlbackups01.blob.core.windows.net/dba01/master.bak'
WITH CREDENTIAL ='SQL_Azure_Backup', COMPRESSION, STATS = 5;
