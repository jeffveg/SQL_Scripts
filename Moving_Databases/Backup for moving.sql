DECLARE @DBName NVARCHAR(255)
	,@BackUpPath NVARCHAR(255)

/* Set DB and Path here */
SET @DBName = N'dbUS-SV-NG01.NextGen.CMS'
SET @BackUpPath = N's:\sqlbackup'

/*********************************************************************/
/*make sure there is a \ at the end of the path  */
IF substring(@BackupPath, len(@BackupPath), 1) <> '\'
	SET @BackupPath = @BackupPath + '\'

DECLARE @CRLF NCHAR(2)
	,@SQL NVARCHAR(4000)

SET @CRLF = CHAR(13) + CHAR(10)
SET @SQL = 'BACKUP DATABASE [' + @DBName + ']' + @CRLF
SET @SQL = @SQL + '  TO DISK = ''' + @BackUpPath + @DBName + '.bak''' + @CRLF
SET @SQL = @SQL + 'WITH ' + @CRLF
SET @SQL = @SQL + '  NOFORMAT ' + @CRLF
SET @SQL = @SQL + '  ,COPY_ONLY ' + @CRLF
SET @SQL = @SQL + ' ,NAME = N''' + @DBName + '-Full Database Backup''' + @CRLF
SET @SQL = @SQL + ' ,SKIP' + @CRLF

/* Compression is not avaaiable in normal SQL server until 2008 */
IF CAST(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(2)) AS DECIMAL) >= 10
	SET @SQL = @SQL + ' ,COMPRESSION' + @CRLF
SET @SQL = @SQL + ' ,STATS = 10;' + @CRLF

PRINT @SQL + @CRLF

EXEC sp_executeSQL @SQL
