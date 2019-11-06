SELECT
 r.session_id, 
 r.request_id as session_request_id,   
 s.group_id,rg.name as pool_name,  
 r.status, 
 s.host_name,   
 CASE WHEN s.login_name = s.original_login_name THEN s.login_name 
 ELSE s.login_name + ' (' + s.original_login_name + ')' 
 END as login_name,
 s.program_name, 
 db_name(r.database_id) as database_name, 
 r.command, 
 substring(st.text,r.statement_start_offset/2 ,
 (CASE WHEN r.statement_end_offset = -1 THEN len(convert(nvarchar(max), st.text)) * 2 
 ELSE r.statement_end_offset 
 END - r.statement_start_offset)/2) as statement,
 r.start_time,
 r.total_elapsed_time as total_elapsed_time_ms,
 r.cpu_time as cpu_time_ms,
 r.wait_type as current_wait_type,
    r.wait_resource as current_wait_resource,
    r.wait_time as current_wait_time_ms,
    r.last_wait_type,
    r.blocking_session_id 
FROM   sys.dm_exec_requests r      
LEFT OUTER JOIN sys.dm_exec_sessions s 
 ON s.session_id = r.session_id         
LEFT OUTER JOIN sys.dm_resource_governor_resource_pools rg 
 ON s.group_id=rg.pool_id             
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st 
WHERE r.session_id<>@@spid 