USE MASTER
Go

SELECT @@SERVERNAME Servername,
CONVERT(VARCHAR(25), DB.name) AS dbName,
CONVERT(VARCHAR(10), DATABASEPROPERTYEX(name, 'status')) AS [Status],
(SELECT COUNT(1) FROM sysaltfiles WHERE DB_NAME(dbid) = DB.name AND groupid !=0 ) AS DataFiles,
(SELECT SUM((size*8)/1024) FROM sysaltfiles WHERE DB_NAME(dbid) = DB.name AND groupid!=0) AS [Data MB],
(SELECT COUNT(1) FROM sysaltfiles WHERE DB_NAME(dbid) = DB.name AND groupid=0) AS LogFiles,
(SELECT SUM((size*8)/1024) FROM sysaltfiles WHERE DB_NAME(dbid) = DB.name AND groupid=0) AS [Log MB],
(SELECT SUM((size*8)/1024) FROM sysaltfiles WHERE DB_NAME(dbid) = DB.name AND groupid!=0)+(SELECT SUM((size*8)/1024) FROM sysaltfiles WHERE DB_NAME(dbid) = DB.name AND groupid=0) TotalSizeMB,
convert(sysname,DatabasePropertyEx(name,'Updateability'))  Updateability,
convert(sysname,DatabasePropertyEx(name,'UserAccess')) UserAccess ,
convert(sysname,DatabasePropertyEx(name,'Recovery')) RecoveryModel ,
convert(sysname,DatabasePropertyEx(name,'Version')) Version ,
CASE cmptlevel
WHEN 60 THEN '60 (SQL Server 6.0)'
WHEN 65 THEN '65 (SQL Server 6.5)'
WHEN 70 THEN '70 (SQL Server 7.0)'
WHEN 80 THEN '80 (SQL Server 2000)'
WHEN 90 THEN '90 (SQL Server 2005)'
WHEN 100 THEN '100 (SQL Server 2008)'
END AS [compatibility level],
CONVERT(VARCHAR(20), crdate, 103) + ' ' + CONVERT(VARCHAR(20), crdate, 108) AS [Creation date],
ISNULL((SELECT TOP 1
CASE TYPE WHEN 'D' THEN 'Full' WHEN 'I' THEN 'Differential' WHEN 'L' THEN 'Transaction log' END + ' – ' +
LTRIM(ISNULL(STR(ABS(DATEDIFF(DAY, GETDATE(),Backup_finish_date))) + ' days ago', 'NEVER')) + ' – ' +
CONVERT(VARCHAR(20), backup_start_date, 103) + ' ' + CONVERT(VARCHAR(20), backup_start_date, 108) + ' – ' +
CONVERT(VARCHAR(20), backup_finish_date, 103) + ' ' + CONVERT(VARCHAR(20), backup_finish_date, 108) +
' (' + CAST(DATEDIFF(second, BK.backup_start_date,
BK.backup_finish_date) AS VARCHAR(4)) + ' '+ 'seconds)'
FROM msdb.dbo.backupset BK WHERE BK.database_name = DB.name ORDER BY backup_set_id DESC),'-') AS [Last backup]
FROM sysdatabases DB
ORDER BY dbName, [Last backup] DESC, NAME
