SELECT
    cat.[Name] AS RptName
  , U.UserName
  , cat.[Path]
  , res.ScheduleID AS JobID
  , sub.LastRuntime
  , sub.LastStatus
  , LEFT(CAST(sch.next_run_date AS CHAR(8)) , 4) + '-'
    + SUBSTRING(CAST(sch.next_run_date AS CHAR(8)) , 5 , 2) + '-'
    + RIGHT(CAST(sch.next_run_date AS CHAR(8)) , 2) + ' '
    + CASE WHEN LEN(CAST(sch.next_run_time AS VARCHAR(6))) = 5
           THEN '0' + LEFT(CAST(sch.next_run_time AS VARCHAR(6)) , 1)
           ELSE LEFT(CAST(sch.next_run_time AS VARCHAR(6)) , 2)
      END + ':'
    + CASE WHEN LEN(CAST(sch.next_run_time AS VARCHAR(6))) = 5
           THEN SUBSTRING(CAST(sch.next_run_time AS VARCHAR(6)) , 2 , 2)
           ELSE SUBSTRING(CAST(sch.next_run_time AS VARCHAR(6)) , 3 , 2)
      END + ':00.000' AS NextRunTime
  , CASE WHEN job.[enabled] = 1 THEN 'Enabled'
         ELSE 'Disabled'
    END AS JobStatus
  , sub.ModifiedDate
  , sub.Description
  , sub.EventType
  , sub.Parameters
  , sub.DeliveryExtension
  , sub.Version
FROM
    dbo.Catalog AS cat
    INNER JOIN dbo.Subscriptions AS sub
        ON cat.ItemID = sub.Report_OID
    INNER JOIN dbo.ReportSchedule AS res
        ON cat.ItemID = res.ReportID
           AND sub.SubscriptionID = res.SubscriptionID
    INNER JOIN msdb.dbo.sysjobs AS job
        ON CAST(res.ScheduleID AS VARCHAR(36)) = job.[name]
    INNER JOIN msdb.dbo.sysjobschedules AS sch
        ON job.job_id = sch.job_id
    INNER JOIN dbo.Users U
        ON U.UserID = sub.OwnerID
ORDER BY
    U.UserName
  , RptName




  