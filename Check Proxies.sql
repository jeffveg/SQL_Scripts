USE msdb

SELECT  j.name JobName
      , p2.name AS JobOwner
      , s.step_id
      --, s.command
      , s.step_name
      , category_id
      , x.name AS ProxyName
FROM    dbo.sysjobsteps s
        LEFT OUTER JOIN sysjobs_view j
            ON s.job_id = j.job_id
        JOIN sys.server_principals p
            ON p.sid = owner_sid
        JOIN sys.server_principals p2
            ON p2.sid = j.owner_sid
        LEFT JOIN dbo.sysproxies x
            ON x.proxy_id = s.proxy_id
WHERE   subsystem = 'SSIS'
        AND ISNULL(s.proxy_id, -1) <> (SELECT   proxy_id
                                       FROM     dbo.sysproxies
                                       WHERE    name = 'Proxy_svcSQLJobs')
        AND j.enabled = 1
       -- AND category_id = 3
ORDER BY j.name
      , s.step_id