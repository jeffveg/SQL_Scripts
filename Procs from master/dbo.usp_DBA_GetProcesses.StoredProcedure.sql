/****** Object:  StoredProcedure [dbo].[usp_DBA_GetProcesses]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_DBA_GetProcesses]
AS

SELECT es.session_id AS spid
,COALESCE(oth.os_thread_id,0) AS kpid
,COALESCE(er.blocking_session_id,0) AS blocked
,COALESCE(er.wait_type,'MISCELLANEOUS') AS waittype
,COALESCE(er.wait_time,0) AS waittime
,COALESCE(er.last_wait_type,'MISCELLANEOUS') AS lastwaittype
,COALESCE(er.wait_resource,'') AS waitresource
,COALESCE(es.database_id,0) AS dbid
,COALESCE(sp.principal_id,0) AS uid
,COALESCE(es.cpu_time,0)
+ COALESCE(er.cpu_time,0) AS cpu
,COALESCE(es.reads,0)
+ COALESCE(es.writes,0)
+ COALESCE(er.reads,0)
+ COALESCE(er.writes,0) AS physical_io
,es.memory_usage AS memusage
,es.login_time
,COALESCE(es.last_request_end_time,es.last_request_start_time) AS last_batch
,COALESCE(ota.exec_context_id,0) AS ecid
,es.open_transaction_count AS open_tran
,es.status
--,es.security_id AS sid
,COALESCE(es.host_name,'') AS hostname
,COALESCE(es.program_name,'') AS program_name
,COALESCE(es.host_process_id,'') AS hostprocess
,COALESCE(er.command,'AWAITING COMMAND') AS cmd
--,COALESCE(es.nt_domain,'') AS nt_domain
--,COALESCE(es.nt_user_name, '') AS nt_username
,COALESCE(client_net_address,'') AS net_address
,COALESCE(net_transport,'') AS net_library
,es.login_name AS loginame
--,es.context_info
--,ec.most_recent_sql_handle AS sql_handle
,COALESCE(er.statement_start_offset,0) AS stmt_start
,COALESCE(er.statement_end_offset,0) AS stmt_end
,COALESCE(er.request_id,0) AS request_id
,GETDATE() AS [AuditDate]
,COALESCE([t].[text],'') AS [Text]
FROM sys.dm_exec_sessions es
LEFT OUTER JOIN sys.dm_exec_connections ec ON es.session_id = ec.session_id
LEFT OUTER JOIN sys.dm_exec_requests er ON es.session_id = er.session_id
LEFT OUTER JOIN sys.server_principals sp ON es.security_id = sp.sid
LEFT OUTER JOIN sys.dm_os_tasks ota ON es.session_id = ota.session_id
LEFT OUTER JOIN sys.dm_os_threads oth ON ota.worker_address = oth.worker_address
OUTER APPLY [sys].[dm_exec_sql_text]([ec].[most_recent_sql_handle]) AS [t]
ORDER BY es.session_id

GO
