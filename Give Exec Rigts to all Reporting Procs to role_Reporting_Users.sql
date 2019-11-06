


DECLARE @SprocName AS SYSNAME
  , @SQL AS NVARCHAR(1000)

DECLARE curSprocGrant CURSOR FAST_FORWARD READ_ONLY
FOR
SELECT  name
FROM    sys.objects
WHERE   name LIKE 'usp_rpt%'
UNION
SELECT  name
FROM    sys.objects
WHERE   name LIKE 'usp_report%' 

OPEN curSprocGrant

FETCH NEXT FROM curSprocGrant INTO @SprocName

WHILE @@FETCH_STATUS = 0 
    BEGIN

        PRINT 'Granting Exec Rights to ' + @SprocName
        SET @SQL = 'GRANT EXEC ON ' + @SprocName + ' TO role_Reporting_Users'
        EXEC sp_executesql @SQL


        FETCH NEXT FROM curSprocGrant INTO @SprocName

    END

CLOSE curSprocGrant
DEALLOCATE curSprocGrant

