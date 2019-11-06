SET NOCOUNT ON 

EXEC sp_updatestats

CREATE TABLE #SHOWCONTIG
    (
      ObjectName CHAR(255),
      ObjectId INT,
      IndexName CHAR(255),
      IndexId INT,
      Lvl INT,
      CountPages INT,
      CountRows INT,
      MinRecSize INT,
      MaxRecSize INT,
      AvgRecSize INT,
      ForRecCount INT,
      Extents INT,
      ExtentSwitches INT,
      AvgFreeBytes INT,
      AvgPageDensity INT,
      ScanDensity DECIMAL,
      BestCount INT,
      ActualCount INT,
      LogicalFrag DECIMAL,
      ExtentFrag DECIMAL
    )
    
PRINT 'Inserting Data'
INSERT
    #ShowContig
    EXEC (
           'DBCC SHOWCONTIG WITH TABLERESULTS'
        )
        
SELECT ObjectName,
	   CountRows,
	   AvgRecSize,
	   ForRecCount,
	   Extents,
	   ExtentSwitches,
	   AvgFreeBytes,
	   AvgPageDensity,
	   ScanDensity,
	   BestCount,
	   ActualCount,
	   LogicalFrag,
	   ExtentFrag  
FROM #SHOWCONTIG
WHERE ObjectId > 100
ORDER BY ObjectName

TRUNCATE TABLE #ShowContig

DECLARE @tblname varchar(200), @execstring nvarchar(4000)

EXEC('
DECLARE defrag_cursor CURSOR FOR 
SELECT 
   a.name  AS tblname
FROM sysobjects a (nolock)
  INNER JOIN sysusers b (nolock)
   ON a.uid = b.uid
WHERE a.name NOT LIKE ''sys%''  
 AND a.name NOT LIKE ''%sys%''
 AND a.name NOT LIKE ''%properties%''
  AND a.name NOT LIKE ''MS%''
  AND a.type = ''U''
GROUP BY  a.name')


OPEN defrag_cursor
  FETCH NEXT FROM defrag_cursor 
    INTO @tblname
  WHILE @@FETCH_STATUS = 0
    BEGIN 
SELECT @execstring = 'DBCC DBREINDEX ( [' + @tblname + '], '''', 80)'
PRINT @execstring
   EXEC sp_executeSQL @execstring


   FETCH NEXT FROM defrag_cursor 
        INTO @tblname
    END
CLOSE defrag_cursor
DEALLOCATE defrag_cursor

   EXEC sp_updatestats

PRINT 'Inserting Data'
INSERT
    #ShowContig
    EXEC (
           'DBCC SHOWCONTIG WITH TABLERESULTS'
        )
        
SELECT ObjectName,
	   CountRows,
	   AvgRecSize,
	   ForRecCount,
	   Extents,
	   ExtentSwitches,
	   AvgFreeBytes,
	   AvgPageDensity,
	   ScanDensity,
	   BestCount,
	   ActualCount,
	   LogicalFrag,
	   ExtentFrag  FROM #SHOWCONTIG
WHERE ObjectId > 100
ORDER BY ObjectName

DROP TABLE #ShowContig