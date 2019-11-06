--SERVER SEARCH - Procs, Jobs, Packages

--Point this to any server, the database doesn't matter
--Set the @Search variable below to whatever you want to search, you do not need the %% wildcards, they're added automatically

--It will search all procs in all databases, jobs, and packages on the server.
--Enjoy

--If you run this multiple times, you'll have to drop the following tables before each run
/*
drop table #output
drop table #dbs
*/


SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @Search nvarchar(100)
declare @version nvarchar(1000)
set @Search = '''''058'''''
select @version = @@version




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

	DECLARE @Packages TABLE
	(PackageName nvarchar(200),
	ShortText varchar(8000))
	
--Part III  Loop through servers and DBs and build output table -------------------------------------------------------------------
	--Variables
	
	declare @db nvarchar(100), @dbid int, @dbmax int, @dbname varchar(100), @sql nvarchar(2000)
	declare @result int


	insert into #dbs 
	(dbname, dbid)
	select name, dbid from master.dbo.sysdatabases 
	where (status < 512 or status between 1023 and 4000000) 
	and name not in ('tempdb','msdb','master','pubs','Northwind') and status2 > 0
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

		IF @version not like 'Microsoft SQL Server  2000%'
		BEGIN
			select @sql = 'insert into #Output ' + char(13) + '(DBName, ProcName )' + char(13) 
			select @sql = @sql + 'select distinct ''' + @db + ''', rtrim(s.name + ''.'' + o.name) as ''ProcName''' + char(13)
			select @sql = @sql + 'from [' + @db + '].sys.objects o (nolock) inner join [' + @db + '].sys.syscomments c on o.object_id = c.id inner join  [' + @db + '].sys.schemas s on o.schema_id = s.schema_id' + char(13)
			select @sql = @sql + 'where c.text like ''%' + @Search + '%'''
		END
	
		IF @version like 'Microsoft SQL Server  2000%'
		BEGIN
			select @sql = 'insert into #Output ' + char(13) + '(DBName, ProcName )' + char(13) 
			select @sql = @sql + 'select distinct ''' + @db + ''', o.name as ''ProcName''' + char(13)
			select @sql = @sql + 'from [' + @db + '].dbo.sysobjects o (nolock) inner join [' + @db + '].dbo.syscomments c on o.id = c.id' + char(13)
			select @sql = @sql + 'where c.text like ''%' + @Search + '%'''
		END
			--select @sql
			exec master.dbo.sp_executesql @sql

		select @counter = @counter + 1
	END

--select * from #dbs
select 'Stored Procs' as SearchType, * from #Output
order by 1,2

--search jobs
	select 'Jobs' as SearchType,
		j.Name as JobName,
		s.Step_Name,
		s.Step_ID,
		s.Command 
	from msdb.dbo.sysjobs j
		inner join msdb.dbo.sysjobsteps s on j.job_id = s.job_id
	where s.command like '%' + @Search + '%'


--Packages
	IF @version NOT like 'Microsoft SQL Server  2000%'
		BEGIN
			insert into @Packages
			(PackageName, ShortText)

			SELECT name AS PackageName,
			left(convert(varchar(max),CONVERT(XML, CONVERT(VARBINARY(MAX), packagedata))),8000) as ShortText
			FROM msdb.dbo.sysdtspackages90

			select 'Packages' as SearchType,
					PackageName
			from @Packages
			where ShortText like '%' + @Search + '%'
		END
	ELSE
		BEGIN	
			SELECT 'Sorry, cannot search SQL 2000 DTS packages!'
		END