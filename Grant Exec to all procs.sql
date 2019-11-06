declare @sql nvarchar(4000)
declare @db  sysname ; set @db = DB_NAME()
declare @u   sysname ; set @u = QUOTENAME('svc_web')

set @sql ='select ''grant exec on '' + QUOTENAME(ROUTINE_SCHEMA) + ''.'' +
QUOTENAME(ROUTINE_NAME) + '' TO ' + @u + ''' FROM INFORMATION_SCHEMA.ROUTINES ' + 
'WHERE OBJECTPROPERTY(OBJECT_ID(ROUTINE_NAME),''IsMSShipped'') = 0'

exec master.dbo.xp_execresultset @sql,@db
