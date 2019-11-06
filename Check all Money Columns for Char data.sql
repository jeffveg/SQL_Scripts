begin tran

Declare @ColumnName as varchar(255)
Declare @SQL as varchar(1000)
Declare @Records int
declare cu cursor for 
	select 
		Name 
	from 
		syscolumns 
	where 
		id = 573245097 -- Table ID from Sysobjects
		and type = 106 -- Money

open cu

fetch next from cu into @ColumnName
while @@fetch_status = 0
begin
	print 'Checking Column ' + @ColumnName
	Set @Sql = 'Select ' + @ColumnName + '  from pbrestaging where isnumeric( ' + @ColumnName + ') = 0'
	Exec( @Sql)
	Set @Sql = 'Update pbrestaging set ' + @ColumnName + ' = 0 where isnumeric( ' + @ColumnName + ') = 0'
print @Sql
	Exec (@Sql)
	fetch next from cu into @ColumnName
end
	
close cu

deallocate cu


-- commit tran
-- rollback tran