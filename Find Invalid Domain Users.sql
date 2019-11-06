
-- Get users not on the domain
EXEC sys.sp_validatelogins

-- Get users Both SQL and Window Orphened users 
Create table #Results (DBName Sysname, OrphenedUser Sysname)

EXEC master..sp_msforeachdb 'use [?] insert into #Results select db_name(),
 name from [?]..sysusers where sid not in(select sid from master..syslogins)
and (isntuser = 1 or isntgroup = 1)'

Select * from #Results Order by DBName 

drop table #Results