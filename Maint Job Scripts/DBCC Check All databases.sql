DECLARE @DBName NVARCHAR(255)
DECLARE @Statment1 NVARCHAR(4000)
DECLARE cDBCCCheck CURSOR FAST_FORWARD READ_ONLY FOR
SELECT name FROM master.sys.databases WHERE name NOT IN ('tempdb') AND state_desc <> 'offline'

OPEN cDBCCCheck

FETCH NEXT FROM cDBCCCheck INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN


SET @Statment1 = 'use [' + @DBName + ']; DBCC CHECKDB(N''' + @DBName + ''') with ALL_ERRORMSGS, NO_INFOMSGS '
print @Statment1 
EXEC sp_executeSQL @Statment1
PRINT '--------------------------------------------------------------------------------------------------------------------------------------------'


FETCH NEXT FROM cDBCCCheck INTO @DBName

END

CLOSE cDBCCCheck 
DEALLOCATE cDBCCCheck 
