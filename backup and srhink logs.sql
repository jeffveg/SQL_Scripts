declare @DBName varchar(30)
declare @SQL nvarchar(2000)

set @DBName = 'NetPerfMon'
set @SQL = '
BACKUP LOG [' + @DBName + '] TO  DISK = N''E:\new\Trans_' + @DBName+ ''' 
WITH NOFORMAT, NOINIT,  
NAME = N'''+ @DBName + ''', 
SKIP, NOREWIND, NOUNLOAD,  STATS = 1

USE [' + @DBName + ']
DBCC SHRINKFILE (2 , 0)'

EXEC sp_executesql @Sql

set @SQL = 'USE [' + @DBName + ']
DBCC SHRINKFILE (2 , 0)'
EXEC sp_executesql @Sql


use master 
select d.name,b.backup_finish_date as trans_backup_finish_date  from sys.databases d
left join (select * from msdb.dbo.backupset bi where type = 'L' and backup_start_date = ( select max(backup_start_date) from msdb.dbo.backupset z where z.database_name = bi.database_name)) b on
b.database_name = d.name
where d.recovery_model = 1 and backup_finish_date is null







 

