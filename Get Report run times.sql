DECLARE @MovAvg TABLE
    (
    Report_X_Date_ID INT
   ,ReportDate DATE
   ,AverageProcessingTime BIGINT
   ,ReportName NVARCHAR(255)
   ,ReportID UNIQUEIDENTIFIER
   ,MovAvg FLOAT
);

INSERT INTO @MovAvg
    (Report_X_Date_ID
    ,ReportDate
    ,AverageProcessingTime
    ,ReportName
    ,ReportID
    ,MovAvg
)
SELECT  ROW_NUMBER () OVER (PARTITION BY el.ReportID ORDER BY el.ReportDate) Report_X_Date_ID
       ,el.ReportDate
       ,el.AverageProcessingTime
       ,REPLACE (el.Name, '.rdl', '') AS ReportName
       ,el.ReportID
       ,AVG (el.AverageProcessingTime) OVER (PARTITION BY el.ReportID
                                             ORDER BY el.ReportDate
                                             ROWS BETWEEN 20 PRECEDING AND 0 FOLLOWING
                                       ) MovAvg
  FROM  dbo.ExecutionLog_DailySummary AS el
  JOIN      (SELECT ReportID
               FROM dbo.ExecutionLog_DailySummary
              WHERE ReportDate > EOMONTH (GETDATE (), -2)
              GROUP BY ReportID
             HAVING COUNT (*) > 3
        ) AS f
    ON f.ReportID = el.ReportID
 WHERE  el.ReportDate > EOMONTH (GETDATE (), -2);

SELECT  ma.ReportDate
       ,ma.ReportName
       ,ma.AverageProcessingTime
       ,ma.MovAvg
  FROM  @MovAvg AS ma
  JOIN      (SELECT TOP 10 ma.ReportID
                   ,(AVG (ma.Report_X_Date_ID * ma.AverageProcessingTime) - AVG (ma.Report_X_Date_ID)
                     * AVG (ma.AverageProcessingTime)
                    ) / VARP (ma.Report_X_Date_ID) AS RegressCoeff
               FROM @MovAvg AS ma
              GROUP BY ma.ReportID
              ORDER BY RegressCoeff DESC
        ) AS f
    ON f.ReportID = ma.ReportID
 WHERE  ma.ReportDate > DATEADD (MONTH, -1, GETDATE ());
--(SELECT  TOP 5 ReportID
--       ,MAX (Name)
--       ,SUM (ReportsRun)
--  FROM  dbo.ExecutionLog_DailySummary
-- GROUP BY ReportID
-- ORDER BY SUM (ReportsRun) DESC;
