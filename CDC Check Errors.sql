SELECT session_id, start_time, end_time, duration, scan_phase,  
    error_count, start_lsn, current_lsn, end_lsn, tran_count  
    last_commit_lsn, last_commit_time, log_record_count, schema_change_count  
    command_count, first_begin_cdc_lsn, last_commit_cdc_lsn,   
    last_commit_cdc_time, latency, empty_scan_count, failed_sessions_count  
FROM sys.dm_cdc_log_scan_sessions  
WHERE session_id = (SELECT MAX(b.session_id) FROM sys.dm_cdc_log_scan_sessions AS b);  
GO  

select * from sys.dm_cdc_errors WHERE session_id = (SELECT MAX(b.session_id) FROM sys.dm_cdc_log_scan_sessions AS b);  

--select * from sys.dm_repl_traninfo

EXECUTE sys.sp_cdc_help_change_data_capture

exec sys.sp_cdc_help_jobs