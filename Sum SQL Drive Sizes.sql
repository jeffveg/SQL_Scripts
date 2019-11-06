DECLARE @MaxDateInserted DATE;

SELECT  @MaxDateInserted = MAX(DateInserted)
FROM    dbo.DatabaseSizeHistory;



SELECT  CASE WHEN sl.ServerIP LIKE '10.1.%' THEN 'Mesa'
             WHEN sl.ServerIP LIKE '10.2.%' THEN 'Scottsdale'
        END
      , sl.Environment
      , DisplayName
      
      , FileType
      , CONVERT(VARCHAR(20), CAST(ROUND(SUM(SpaceUsed) / 128.0 / 1024, 2) AS MONEY), 101) AS Data_GB
      , CONVERT(VARCHAR(20), CAST(ROUND(SUM(size) / 128.0 / 1024, 2) AS MONEY), 101) AS SpaceAllocated_GB
      , sl.Notes
FROM    DatabaseSizeHistory dsh
        JOIN dbo.Server_List sl
            ON sl.SLID = dsh.SLID
WHERE   DateInserted = @MaxDateInserted
        AND sl.SLID NOT IN (79)
        AND (sl.ServerIP LIKE '10.1.%'
             OR sl.ServerIP LIKE '10.2.%'
            )
GROUP BY CASE WHEN sl.ServerIP LIKE '10.1.%' THEN 'Mesa'
              WHEN sl.ServerIP LIKE '10.2.%' THEN 'Scottsdale'
         END
      , sl.Environment
      , DisplayName
      , FileType
      , sl.Notes
ORDER BY CASE WHEN sl.ServerIP LIKE '10.1.%' THEN 'Mesa'
              WHEN sl.ServerIP LIKE '10.2.%' THEN 'Scottsdale'
         END
      , sl.Environment
      , DisplayName
      , FileType;