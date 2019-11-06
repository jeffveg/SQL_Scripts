SET NOCOUNT ON

DECLARE @RemotePath VARCHAR(255)
	, @LocalPath VARCHAR(255)
	, @DataFilePath NVARCHAR(2000)
	, @LogFilePath NVARCHAR(2000)
	, @COMPATIBILITY_LEVEL VARCHAR(4)
	, @ForceSimpleMode BIT
	, @Quote CHAR(1)
	, @QCQ CHAR(3)

SET @RemotePath = N'\\attsqlcalldb01\c$\Move\'
SET @LocalPath = 'S:\SQLBackup\'
SET @DataFilePath = 'D:\SQLData\'
SET @LogFilePath = 'L:\SQLLogs\'
SET @COMPATIBILITY_LEVEL = '120'
SET @ForceSimpleMode = 0
SET @Quote = ''''
SET @QCQ = ''','''

PRINT '-- Full Backup Restore '

SELECT 'exec usp_RestoreFullForMove ' + @Quote + NAME + @QCQ + @RemotePath + @QCQ + @LocalPath + @QCQ + @DataFilePath + @QCQ + @LogFilePath + @Quote
FROM sys.databases
WHERE STATE = 0
	AND NAME NOT IN (
		'master'
		, 'tempdb'
		, 'model'
		, 'msdb'
		)
	AND source_database_id IS NULL
	AND is_encrypted = 0
ORDER BY NAME

PRINT '-- Diff Backup Restore '

SELECT 'exec usp_RestoreDiffForMove ' + @Quote + NAME + @QCQ + @RemotePath + @QCQ + @LocalPath + @QCQ + @DataFilePath + @QCQ + @LogFilePath + @QCQ + @COMPATIBILITY_LEVEL + @Quote
FROM sys.databases
WHERE STATE = 0
	AND NAME NOT IN (
		'master'
		, 'tempdb'
		, 'model'
		, 'msdb'
		)
	AND source_database_id IS NULL
	AND is_encrypted = 0
ORDER BY NAME
