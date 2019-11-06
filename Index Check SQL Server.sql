SET NOCOUNT ON 

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

PRINT 'Tables without clustered indexes '
SELECT
    ObjectName,
    ObjectID
FROM
    #ShowContig
WHERE
    LEN(IndexName) = 0
    AND ObjectName NOT LIKE 'dt%'
    AND ObjectName NOT LIKE 'sys%'
ORDER BY
    ObjectName

PRINT 'Top ten tables with the most data pages (does not include non-clustered index pages).'
SELECT TOP 10
    ObjectName,
    IndexName,
    countpages
FROM
    #ShowContig
WHERE
    ObjectName NOT LIKE 'dt%'
    AND ObjectName NOT LIKE 'sys%'
ORDER BY
    countpages DESC

PRINT 'Top ten tables with the highest row counts'
SELECT TOP 10
    ObjectName,
    IndexName,
    CountRows
FROM
    #ShowContig
WHERE
    ObjectName NOT LIKE 'dt%'
    AND ObjectName NOT LIKE 'sys%'
ORDER BY
    CountRows DESC

PRINT 'Top ten tables with the largest average record size'
SELECT TOP 10
    ObjectName,
    IndexName,
    AvgRecSize
FROM
    #ShowContig
WHERE
    ObjectName NOT LIKE 'dt%'
    AND ObjectName NOT LIKE 'sys%'
ORDER BY
    AvgRecSize DESC

PRINT 'Top ten tables with the largest record sizes'
SELECT TOP 10
    ObjectName,
    IndexName,
    MaxRecSize
FROM
    #ShowContig
WHERE
    ObjectName NOT LIKE 'dt%'
    AND ObjectName NOT LIKE 'sys%'
ORDER BY
    MaxRecSize DESC



PRINT 'Top ten tables with the highest average bytes free per page'

SELECT TOP 10
    ObjectName,
    IndexName,
    AvgFreeBytes
FROM
    #ShowContig
WHERE
    ObjectName NOT LIKE 'dt%'
    AND ObjectName NOT LIKE 'sys%'
ORDER BY
    AvgFreeBytes DESC


PRINT 'Top ten tables with the LOWEST average page density'

SELECT TOP 10
    ObjectName,
    IndexName,
    AvgPageDensity
FROM
    #ShowContig
WHERE
    ObjectName NOT LIKE 'dt%'
    AND ObjectName NOT LIKE 'sys%'
ORDER BY
    AvgPageDensity ASC
	
	
PRINT 'Top ten tables with the highest amount of logical fragmentation'

SELECT TOP 10
    ObjectName,
    IndexName,
    logicalfrag
FROM
    #ShowContig
WHERE
    ObjectName NOT LIKE 'dt%'
    AND ObjectName NOT LIKE 'sys%'
ORDER BY
    logicalfrag DESC
	
	
PRINT 'Top ten tables with the highest extent fragmentation'

SELECT TOP 10
    ObjectName,
    IndexName,
    ExtentFrag
FROM
    #ShowContig
WHERE
    ObjectName NOT LIKE 'dt%'
    AND ObjectName NOT LIKE 'sys%'
ORDER BY
    ExtentFrag DESC

PRINT 'Top ten tables with the lowest scan density'

SELECT TOP 10
    ObjectName,
    IndexName,
    ScanDensity
FROM
    #ShowContig
WHERE
    ObjectName NOT LIKE 'dt%'
    AND ObjectName NOT LIKE 'sys%'
ORDER BY
    ScanDensity ASC

DROP TABLE #SHOWCONTIG