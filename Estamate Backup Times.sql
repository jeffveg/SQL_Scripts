/*
Queries the dm_exec requests and gives you an estimate of how long a backup/restore request is going to take

No Configuration needed

Author: mig.qui@gmail.com  (however, I think I just found it on the internet)

Compatibility list:
MSSQL2005
MSSQL2008
MSSQL2008R2
MSSQL2012

DOES NOT WORK
MSSQL2000

*/


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