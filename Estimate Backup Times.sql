
SELECT 
session_id as SPID
, r.command
, a.text AS Query
, start_time
, percent_complete
, dateadd(second,estimated_completion_time/1000
, getdate()) as estimated_completion_time
, r.blocking_session_id
, r.wait_type
FROM sys.dm_exec_requests r 
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a
WHERE 1=1 
and r.command in ('BACKUP DATABASE','BACKUP LOG','RESTORE DATABASE') 


SELECT r.session_id,r.command,CONVERT(NUMERIC(6,2),r.percent_complete)
AS [Percent Complete],CONVERT(VARCHAR(20),DATEADD(ms,r.estimated_completion_time,GetDate()),20) AS [ETA Completion Time],
CONVERT(NUMERIC(10,2),r.total_elapsed_time/1000.0/60.0) AS [Elapsed Min],
CONVERT(NUMERIC(10,2),r.estimated_completion_time/1000.0/60.0) AS [ETA Min],
CONVERT(NUMERIC(10,2),r.estimated_completion_time/1000.0/60.0/60.0) AS [ETA Hours],
CONVERT(VARCHAR(1000),(SELECT SUBSTRING(text,r.statement_start_offset/2,
CASE WHEN r.statement_end_offset = -1 THEN 1000 ELSE (r.statement_end_offset-r.statement_start_offset)/2 END)
FROM sys.dm_exec_sql_text(sql_handle))) AS [SQL]
FROM sys.dm_exec_requests r WHERE command IN ('RESTORE DATABASE','BACKUP DATABASE')