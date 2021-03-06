/****** Object:  StoredProcedure [dbo].[sp_DBA_BackupToAzureDiff]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_DBA_BackupToAzureDiff]
(
	@storage VARCHAR(30)
	,@container VARCHAR(100)
	,@credential VARCHAR(65)
)
AS
DECLARE @BackUpPath NVARCHAR(1000)
--SET @BackUpPath = 'L:\Backups\'
SET @BackUpPath = 'https://' + @storage + '.blob.core.windows.net/'

DECLARE @DTStamp VARCHAR(28)
DECLARE @Statment NVARCHAR(4000)
DECLARE @DBName NVARCHAR(255)


SET @DTStamp = CONVERT(VARCHAR(28),GETDATE(),121)
SET @DTStamp = REPLACE(@DTStamp,'-','_')
SET @DTStamp = REPLACE(@DTStamp,' ','_')
SET @DTStamp = REPLACE(@DTStamp,':','')
SET @DTStamp = REPLACE(@DTStamp,'.','_')

--PRINT @DTStamp

DECLARE cBackup CURSOR FAST_FORWARD READ_ONLY FOR
SELECT name FROM master.sys.databases WHERE name not in ('tempdb','master') 

OPEN cBackup

FETCH NEXT FROM cBackup INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @Statment = 'BACKUP database [' + @DBName + '] TO URL = ''' + @BackUpPath + @container + '/' + @DBName + '_Diff_' + @DTStamp +'.bak'' WITH CREDENTIAL =''' + @credential + ''', COMPRESSION, DIFFERENTIAL, STATS = 5;'
	EXEC sp_executeSQL @Statment
	--PRINT @Statment

	FETCH NEXT FROM cBackup INTO @DBName

END

CLOSE cBackup
DEALLOCATE cBackup
GO
