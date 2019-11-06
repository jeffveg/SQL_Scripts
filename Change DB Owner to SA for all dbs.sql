


DECLARE @DBName SYSNAME
  , @SQL NVARCHAR(2000)

DECLARE cur CURSOR FAST_FORWARD READ_ONLY
FOR
SELECT  name
FROM    sys.databases
WHERE   owner_sid <> 0x01

OPEN cur

FETCH NEXT FROM cur INTO @DBName

WHILE @@FETCH_STATUS = 0 
    BEGIN


        SET @sql = 'use [' + @DBName + ']; exec sp_changedbowner ''sa'''
        PRINT @SQL
        EXEC sp_executesql @SQL

        FETCH NEXT FROM cur INTO @DBName


    END

CLOSE cur
DEALLOCATE cur




















