SELECT *
FROM msdb.dbo.sysjobs j
    JOIN msdb.dbo.sysjobsteps s
        ON s.job_id = j.job_id
WHERE s.step_id = 1
      AND s.step_name <> N'Check if Primary'
      --AND CASE
      --        WHEN UPPER(j.name) LIKE '[A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9]-[A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9]-[A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9]-[A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9]-[A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9][A-F,0-9]' THEN
      --            'Likely SSRS Job'
      --        WHEN
      --        (
      --            j.name LIKE 'DBA%'
      --            OR j.name = 'SSIS Failover Monitor Job'
      --            OR j.name = 'SSIS Server Maintenance Job'
      --            OR j.name LIKE 'cdc%'
      --        ) THEN
      --            'Do not include'
      --        ELSE
      --            'Needs Step'
      --    END = 'Needs Step'
ORDER BY j.name;