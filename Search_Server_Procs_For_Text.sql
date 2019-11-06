--Point this to any server
--Set the @Search variable below to whatever you want to search
--the proc text for, you do not need the %% wildcards, they're added automatically
--Enjoy


SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @Search nvarchar(100)
set @Search = 'SKL05'

/*
drop table #output
drop table #dbs
*/

	--For the DBs on each server
	create table #dbs  
	(	databaseID int identity (1,1),
		dbname varchar(100),
		dbid int
	)

	create table #Output 
(	RowId int identity(1,1),
	DBName varchar(100),
	ProcName nvarchar(200))

--Part III  Loop through servers and DBs and build output table -------------------------------------------------------------------
	--Variables
	
	declare @db nvarchar(100), @dbid int, @dbmax int, @dbname varchar(100), @sql nvarchar(2000)
	declare @result int

	

	insert into #dbs 
	(dbname, dbid)
	select name, dbid from master.dbo.sysdatabases 
	where (status < 512 or status between 1023 and 4000000) 
	and name not in ('tempdb','msdb','master') and status2 > 0
	order by dbid

	
	declare @counter int, @maxrows int
	declare @text varchar(8000)
	DECLARE @vInputLength        INT
	DECLARE @vIndex              INT
	DECLARE @vCount              INT

	select @counter = 1, @maxrows = (select count(*) from #dbs)
		
	WHILE @Counter <= @MaxRows
	BEGIN
		
		select @db = (select dbname from #dbs where databaseID = @counter)

			select @sql = 'insert into #Output ' + char(13) + '(DBName, ProcName )' + char(13) 
			select @sql = @sql + 'select distinct ''' + @db + ''', rtrim(s.name + ''.'' + o.name) as ''ProcName''' + char(13)
			select @sql = @sql + 'from [' + @db + '].sys.objects o (nolock) inner join [' + @db + '].sys.syscomments c on o.object_id = c.id inner join  [' + @db + '].sys.schemas s on o.schema_id = s.schema_id' + char(13)
			select @sql = @sql + 'where c.text like ''%' + @Search + '%'''
	
			--select @sql
			exec master.dbo.sp_executesql @sql

		select @counter = @counter + 1
	END

--select * from #dbs
select * from #Output
order by 1,2