
DECLARE @SQL NVARCHAR(1000)

SET @SQL = 
'
Declare @svcJobsName nvarchar(100)

use [?]
SELECT DB_NAME()

select
    @svcJobsName = name
from
    sys.database_principals
where
    sid = (select sid from sys . server_principals where name =
            ''NTBANK\svcSQLJob'')

if @@Rowcount = 0 
begin
    CREATE USER [NTBANK\svcSQLJob] FOR LOGIN [NTBANK\svcSQLJob] 
	Set @svcJobsName = ''NTBANK\svcSQLJob''
	Print ''Created User '' + @svcJobsName
end

EXEC sp_addrolemember N''db_ddladmin'', @svcJobsName
EXEC sp_addrolemember N''db_backupoperator'', @svcJobsName
EXEC sp_addrolemember N''db_datareader'', @svcJobsName
EXEC sp_addrolemember N''db_datawriter'', @svcJobsName
print ''Updated Roles for '' + @svcJobsName
'
exec sp_MSForEachDB @SQL


/*

--For SQL 2000


DECLARE @SQL NVARCHAR(1000)

SET @SQL = 
'
Declare @svcJobsName nvarchar(100)

use [?]
SELECT DB_NAME()

select
    @svcJobsName = name
from
    master.dbo.syslogins
where
    sid = (select sid from master.dbo.syslogins where name =
            ''NTBANK\svcSQLJob'')

if @@Rowcount = 0 
begin
	exec sp_grantdbaccess @loginame   = N''NTBANK\svcSQLJob'', 
		 @name_in_db = N''NTBANK\svcSQLJob''
	Print ''Created User '' + @svcJobsName
end

EXEC sp_addrolemember N''db_ddladmin'', @svcJobsName
EXEC sp_addrolemember N''db_backupoperator'', @svcJobsName
EXEC sp_addrolemember N''db_datareader'', @svcJobsName
EXEC sp_addrolemember N''db_datawriter'', @svcJobsName
print ''Updated Roles for '' + @svcJobsName
'
exec sp_MSForEachDB @SQL





*/