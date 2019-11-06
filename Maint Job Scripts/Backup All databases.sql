DECLARE @BackUpPath NVARCHAR(1000)
SET @BackUpPath = 'd:\Backups\'

DECLARE @DTStamp VARCHAR(28)
DECLARE @DTDelete VARCHAR(28)
DECLARE @Statment NVARCHAR(4000)
DECLARE @DBName NVARCHAR(255)


SET @DTDelete = CONVERT(VARCHAR(19),DATEADD(day,-3,GETDATE()),121)
SET @DTDelete = REPLACE(@DTDelete,' ','T')
SET @DTStamp = CONVERT(VARCHAR(28),GETDATE(),121)
SET @DTStamp = REPLACE(@DTStamp,'-','_')
SET @DTStamp = REPLACE(@DTStamp,' ','_')
SET @DTStamp = REPLACE(@DTStamp,':','')
SET @DTStamp = REPLACE(@DTStamp,'.','_')

PRINT @DTStamp

DECLARE cBackup CURSOR FAST_FORWARD READ_ONLY FOR
SELECT name FROM master.sys.databases WHERE name not in ('Tempdb')

OPEN cBackup

FETCH NEXT FROM cBackup INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @Statment = 'EXECUTE master.dbo.xp_create_subdir ''' + @BackUpPath + @DBName + ''''
	EXEC sp_executeSQL @Statment

	SET @Statment = 'EXECUTE master.dbo.xp_delete_file 0,N''' + @BackUpPath + @DBName + ''',N''bak'',N''' + @DTDelete + ''',1'
	EXEC sp_executeSQL @Statment

	SET @Statment =  'BACKUP DATABASE [' + @DBName + '] TO  DISK = ''' + @BackUpPath + @DBName + '\' + @DBName + '_backup_' + @DTStamp +'.bak'' WITH NOFORMAT, NOINIT, NAME = ''' + @DBName + 'backup_' + @DTStamp + ''', SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 10'
	EXEC sp_executeSQL @Statment

	FETCH NEXT FROM cBackup INTO @DBName

END

CLOSE cBackup
DEALLOCATE cBackup
