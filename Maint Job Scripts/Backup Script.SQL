
DECLARE @BackUpPath NVARCHAR(1000)
SET @BackUpPath = 'G:\Backup\SystemDBs\'



DECLARE @DTStamp VARCHAR(28)
DECLARE @Statment1 NVARCHAR(4000)
DECLARE @Statment2 NVARCHAR(4000)
DECLARE @DBName NVARCHAR(255)


SET @DTStamp = CONVERT(VARCHAR(28),GETDATE(),121)
SET @DTStamp = REPLACE(@DTStamp,'-','_')
SET @DTStamp = REPLACE(@DTStamp,' ','_')
SET @DTStamp = REPLACE(@DTStamp,':','')
SET @DTStamp = REPLACE(@DTStamp,'.','_')


PRINT @DTStamp


DECLARE cBackup CURSOR FAST_FORWARD READ_ONLY FOR
SELECT name FROM master.sys.databases WHERE name in ('Master','Model','MSDB')

OPEN cBackup

FETCH NEXT FROM cBackup INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN

PRINT @DBName
SET @Statment1 = 'EXECUTE master.dbo.xp_create_subdir ''' + @BackUpPath + @DBName + ''''
EXEC sp_executeSQL @Statment1

SET @Statment2 =  'BACKUP DATABASE [' + @DBName + '] TO  DISK = ''' + @BackUpPath + @DBName + '\' + @DBName + '_backup_' + @DTStamp +'.bak'' WITH NOFORMAT, NOINIT, NAME = ''' + @DBName + 'backup_' + @DTStamp + ''', SKIP, REWIND, NOUNLOAD,  STATS = 10'
EXEC sp_executeSQL @Statment2

FETCH NEXT FROM cBackup INTO @DBName

END

CLOSE cBackup
DEALLOCATE cBackup


SET @DTStamp = CONVERT(VARCHAR(19),DATEADD(day,-3,GETDATE()),121)
SET @DTStamp = REPLACE(@DTStamp,' ','T')

--PRINT @DTStamp
SET @Statment1 = 'EXECUTE master.dbo.xp_delete_file 0,N''' + @BackUpPath + ''',N''bak'',N''' + @DTStamp + ''',1'
EXEC sp_executeSQL @Statment1
