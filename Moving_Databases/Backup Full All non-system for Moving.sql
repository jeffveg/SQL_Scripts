DECLARE @DBName NVARCHAR(255)
	, @BackUpPath NVARCHAR(255)
	, @Message NVARCHAR(255)
	, @CRLF NCHAR(2)
	, @SQL NVARCHAR(4000)

SET @BackUpPath = N'c:\move\'
SET @CRLF = CHAR(13) + CHAR(10)

-- =============================================
-- Declare and using a READ_ONLY cursor
-- =============================================
DECLARE cBackup CURSOR READ_ONLY
FOR
SELECT NAME
FROM sys.databases
WHERE STATE = 0
	AND NAME NOT IN (
		'master'
		, 'tempdb'
		, 'model'
		, 'msdb'
		, 'distribution'
		)
	AND source_database_id IS NULL
	and is_encrypted = 0
ORDER BY NAME;

OPEN cBackup

FETCH NEXT
FROM cBackup
INTO @DBName

WHILE (@@fetch_status <> - 1)
BEGIN
	IF (@@fetch_status <> - 2)
	BEGIN
		SET @Message = 'Full Backup for database ' + @DBName

		RAISERROR (
				@Message
				, 0
				, 1
				)
		WITH NOWAIT

		/*********************************************************************/
		/*make sure there is a \ at the end of the path  */
		IF substring(@BackupPath, len(@BackupPath), 1) <> '\'
			SET @BackupPath = @BackupPath + '\'
		SET @SQL = 'BACKUP DATABASE ' + @DBName + @CRLF
		SET @SQL = @SQL + '  TO DISK = ''' + @BackUpPath + @DBName + '.bak''' + @CRLF
		SET @SQL = @SQL + 'WITH ' + @CRLF
		SET @SQL = @SQL + '  NOFORMAT ' + @CRLF
		SET @SQL = @SQL + ' ,NAME = N''' + @DBName + '-Full Database Backup''' + @CRLF
		SET @SQL = @SQL + ' ,SKIP' + @CRLF

		/* Compression is not avaaiable in normal SQL server until 2008 */
		IF CAST(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(2)) AS DECIMAL) >= 10
			SET @SQL = @SQL + ' ,COMPRESSION' + @CRLF
		SET @SQL = @SQL + ' ,STATS = 10 '

		--PRINT @SQL + @CRLF
		EXEC sp_executeSQL @SQL
	END

	FETCH NEXT
	FROM cBackup
	INTO @DBName
END

CLOSE cBackup

DEALLOCATE cBackup
GO


