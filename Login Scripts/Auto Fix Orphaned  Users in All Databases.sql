
/********************************************************
*	This script will try to auto fix all users in all	*
*	databases											*
********************************************************/


DECLARE @Sql NVARCHAR(4000)


--DROP TABLE #Temp

--CREATE TABLE #Temp (Uname VARCHAR(200), USid VARBINARY(500))

TRUNCATE TABLE #Temp


INSERT INTO #temp 
EXEC sp_msforeachdb 'use [?]; EXEC sp_change_users_login ''Report'''


SELECT uname,COUNT(*) FROM #Temp GROUP BY Uname
ORDER BY 2 desc


DECLARE @DBUser VARCHAR(200)


DECLARE cCur CURSOR FAST_FORWARD READ_ONLY FOR
SELECT uname FROM #Temp WHERE uname <> 'DBO' GROUP BY Uname

OPEN cCur

FETCH NEXT FROM cCur INTO @DBUser

WHILE @@FETCH_STATUS = 0
BEGIN


SET @Sql = 'EXEC sp_msforeachdb ''use [?]; EXEC sp_change_users_login ''''AUTO_FIX'''', [' +  @DBUser  + ']'''
 
 
 /* Hey instead of fixing you can drop the users instead :-)  */
 --SET @Sql = 'EXEC sp_msforeachdb ''use [?];  DROP USER ' +  @DBUser  + ''''

PRINT @Sql
EXEC sp_executesql @SQL 


FETCH NEXT FROM cCur INTO @DBUser

END

CLOSE cCur
DEALLOCATE cCur



TRUNCATE TABLE #Temp

INSERT INTO #temp 
EXEC sp_msforeachdb 'use [?]; EXEC sp_change_users_login ''Report'''

SELECT uname,COUNT(*) FROM #Temp GROUP BY Uname
ORDER BY 2 desc



 
 