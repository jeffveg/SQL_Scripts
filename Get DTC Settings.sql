SET NOCOUNT ON

USE master
GO

DECLARE @config SQL_VARIANT
DECLARE @advanced SQL_VARIANT

SELECT @advanced = value
FROM sys.configurations
WHERE NAME = 'show advanced options'

IF @advanced = 0
BEGIN
	EXEC sp_configure 'show advanced options'
		, 1

	RECONFIGURE
END

SELECT @config = value
FROM sys.configurations
WHERE NAME = 'xp_cmdshell'

IF @config = 0
BEGIN
	EXEC sp_configure 'xp_cmdshell'
		, 1

	RECONFIGURE
END

DECLARE @SQL NVARCHAR(4000)

CREATE TABLE #TempServiceUser (TEXT VARCHAR(2000))

SET @Sql = 'WMIC SERVICE get state,Caption' --WHERE "Name = ''MSSQL$' + cast(SERVERPROPERTY('InstanceName') as varchar(30)) + '''" get Caption,StartName'

INSERT INTO #TempServiceUser
EXEC xp_cmdshell @Sql

SELECT *
FROM #TempServiceUser
WHERE TEXT LIKE '%Distributed Transaction Coordinator%'

DROP TABLE #TempServiceUser

IF @config = 0
BEGIN
	EXEC sp_configure 'xp_cmdshell'
		, 0

	RECONFIGURE
END

IF @advanced = 0
BEGIN
	EXEC sp_configure 'show advanced options'
		, 0

	RECONFIGURE
END
