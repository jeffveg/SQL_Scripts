USE master
GO

IF EXISTS (
		SELECT 1
		FROM sys.objects
		WHERE NAME = 'usp_RestoreDiffForMove'
		)
	DROP PROCEDURE usp_RestoreDiffForMove
GO

CREATE PROCEDURE usp_RestoreDiffForMove (
	@DBName VARCHAR(255)
	, @RemotePath VARCHAR(255)
	, @LocalPath VARCHAR(255)
	, @DataFilePath NVARCHAR(2000)
	, @LogFilePath NVARCHAR(2000)
	, @COMPATIBILITY_LEVEL VARCHAR(4)
	, @ForceSimpleMode BIT = 0
	)
AS
/* Restore */
DECLARE @RemoteBAKFileName NVARCHAR(2000)
	, @LocalBAKFileName NVARCHAR(2000)

/* Make sure paths end with "\"*/
IF substring(@RemotePath, len(@RemotePath), 1) <> '\'
	SET @RemotePath = @RemotePath + '\'

IF substring(@LocalPath, len(@LocalPath), 1) <> '\'
	SET @LocalPath = @LocalPath + '\'

IF substring(@DataFilePath, len(@DataFilePath), 1) <> '\'
	SET @DataFilePath = @DataFilePath + '\'

IF substring(@LogFilePath, len(@LogFilePath), 1) <> '\'
	SET @LogFilePath = @LogFilePath + '\'
SET @RemoteBAKFileName = @RemotePath + @Dbname + '_Diff.bak'
SET @LocalBAKFileName = @LocalPath + @Dbname + '_Diff.bak'

--SET @COMPATIBILITY_LEVEL = '100'
--SET @SimpleMode = 'TRUE'
/*******************************************/
/* See if we can See the cmd shell setting*/
DECLARE @AdvanceOptions INT
DECLARE @CmdShell INT

CREATE TABLE #Configure (
	NAME SYSNAME
	, [Min] INT
	, [Max] INT
	, Config_Value INT
	, Run_value INT
	)

INSERT INTO #Configure (
	NAME
	, Min
	, Max
	, Config_Value
	, Run_value
	)
EXEC sp_configure 'show advanced options'

SELECT @AdvanceOptions = Config_Value
FROM #Configure

/* Set Advance options if needed */
IF @AdvanceOptions = 0
BEGIN
	EXEC sp_configure 'show advanced options'
		, 1

	RECONFIGURE
END

DELETE #Configure

/* Retreve the comand shell setting */
INSERT INTO #Configure (
	NAME
	, Min
	, Max
	, Config_Value
	, Run_value
	)
EXEC sp_configure 'xp_cmdshell'

SELECT @CmdShell = Config_Value
FROM #Configure

/* Set to 1 if needed */
IF @CmdShell = 0
BEGIN
	EXEC sp_configure 'xp_cmdshell'
		, 1

	RECONFIGURE
END

DECLARE @SQL NVARCHAR(4000)

SET @SQL = 'copy ' + @RemoteBAKFileName + ' ' + @LocalBAKFileName

PRINT @SQL

EXEC xp_cmdshell @SQL

CREATE TABLE #Temp (
	LogicalName NVARCHAR(128)
	, PhysicalName NVARCHAR(260)
	, Type CHAR(1)
	, FileGroupName NVARCHAR(128)
	, Size NUMERIC(20, 0)
	, MaxSize NUMERIC(20, 0)
	, FileID BIGINT
	, CreateLSN NUMERIC(25, 0)
	, DropLSN NUMERIC(25, 0) NULL
	, UniqueID UNIQUEIDENTIFIER
	, ReadOnlyLSN NUMERIC(25, 0) NULL
	, ReadWriteLSN NUMERIC(25, 0) NULL
	, BackupSizeInBytes BIGINT
	, SourceBlockSize INT
	, FileGroupID INT
	, LogGroupGUID UNIQUEIDENTIFIER
	, DifferentialBaseLSN NUMERIC(25, 0)
	, DifferentialBaseGUID UNIQUEIDENTIFIER
	, IsReadOnly BIT
	, IsPresent BIT
	, TDEThumbprint VARBINARY(32)
	-- 2016, SnapshotUrl  NVARCHAR(360)
	)

SET @SQL = 'RESTORE filelistonly FROM DISK = ''' + @LocalBAKFileName + ''' WITH NOUNLOAD; '

INSERT INTO #Temp
EXEC sp_executeSQL @SQL

--select * from #Temp
DECLARE @CRLF CHAR(2)

SET @CRLF = CHAR(13) + CHAR(10)

DECLARE @DataName VARCHAR(255)
DECLARE @DataPhyName VARCHAR(255)
DECLARE @FileType VARCHAR(10)

SET @SQL = 'RESTORE DATABASE ' + @DBName + @CRLF
SET @SQL = @SQL + '  FROM Disk =''' + @LocalBAKFileName + '''' + @CRLF
SET @SQL = @SQL + '   WITH RECOVERY, ' + @CRLF

DECLARE cRestore CURSOR READ_ONLY
FOR
SELECT LogicalName
	, PhysicalName
	, Type
FROM #Temp
ORDER BY FileID

DECLARE @name VARCHAR(40)

OPEN cRestore

FETCH NEXT
FROM cRestore
INTO @DataName
	, @DataPhyName
	, @FileType
WHILE (@@fetch_status <> - 1)
BEGIN
	IF (@@fetch_status <> - 2)
	BEGIN
		SET @DataPhyName = right(@DataPhyName, charindex('\', reverse(@DataPhyName)) - 1)
		SET @SQL = @SQL + '     MOVE ''' + @DataName + ''' TO ' + @CRLF
		IF @FileType = 'D'
			SET @SQL = @SQL + '      ''' + @DataFilePath + @DataPhyName + ''', ' + @CRLF
		ELSE
			SET @SQL = @SQL + '      ''' + @LogFilePath + @DataPhyName + ''', ' + @CRLF
	END

	FETCH NEXT
	FROM cRestore
	INTO @DataName
		, @DataPhyName
		, @FileType
END

CLOSE cRestore

DEALLOCATE cRestore

SET @SQL = SUBSTRING(@SQL, 1, LEN(@SQL) - 4)

PRINT @SQL

EXEC sp_executeSQL @SQL

SET @SQL = 'USE [master]' + @CRLF
SET @SQL = @SQL + 'ALTER DATABASE [' + @DBName + '] SET COMPATIBILITY_LEVEL = ' + @COMPATIBILITY_LEVEL + @CRLF

IF @ForceSimpleMode = 1
	SET @SQL = @SQL + 'ALTER DATABASE [' + @DBName + '] SET RECOVERY SIMPLE WITH NO_WAIT' + @CRLF

PRINT @SQL

EXEC sp_executeSQL @SQL

DECLARE @SAUser SYSNAME

SELECT @SAUser = NAME
FROM sys.sql_logins
WHERE sid = 0x01

SET @SQL = 'Use [' + @DBName + ']; exec sp_ChangeDBOwner ''' + @SAUser +''''

PRINT @SQL

EXEC sp_executeSQL @SQL



DROP TABLE #Temp

SET @SQL = 'del ' + @LocalBAKFileName

EXEC xp_cmdshell @SQL

/* Reset cmd shell setting if needed */
IF @CmdShell = 0
BEGIN
	EXEC sp_configure 'xp_cmdshell'
		, 0

	RECONFIGURE
END

/* Reset Advanced options if neede */
IF @AdvanceOptions = 0
BEGIN
	EXEC sp_configure 'show advanced options'
		, 0

	RECONFIGURE
END

DROP TABLE #Configure
