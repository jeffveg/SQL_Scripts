CREATE table #Table ( OUTPUT VARCHAR(2000))
INSERT INTO #Table
EXEC xp_cmdshell  'ipconfig /all'

SELECT LTRIM(REPLACE(OUTPUT, 'Primary Dns Suffix  . . . . . . . :' ,'')) Domain FROM #Table WHERE OUTPUT LIKE   '%Primary Dns Suffix%'

