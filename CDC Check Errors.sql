SELECT session_id,
       start_time,
       end_time,
       duration,
       scan_phase,
       error_count,
       --start_lsn,
       --current_lsn,
       --end_lsn,
       tran_count, command_count,
       last_commit_time,
       Admin_Scripts.dbo.udf_Chameleon_Int(log_record_count) log_record_count,
       --schema_change_count command_count,
       --first_begin_cdc_lsn,
       --last_commit_cdc_lsn,
       last_commit_cdc_time,
       latency,
       empty_scan_count,
       failed_sessions_count, datediff( MINUTE,last_commit_time,GETDATE()) MinBehind
FROM sys.dm_cdc_log_scan_sessions
WHERE session_id in 
(
    SELECT TOP 5 b.session_id FROM sys.dm_cdc_log_scan_sessions  AS b ORDER BY b.session_id DESC
);
--WAITFOR DELAY '00:01:00'
--GO 10

SELECT command_count/duration AS [Throughput] FROM sys.dm_cdc_log_scan_sessions WHERE session_id = 0

SELECT *
FROM sys.dm_cdc_errors
WHERE session_id =
(
    SELECT MAX(b.session_id) FROM sys.dm_cdc_log_scan_sessions AS b
);
--SELECT
--    [AllocUnitName] as [ObjectName],
--    [Page ID],
--    [Current LSN],
--    [Operation],
--    [Context],
--    [Transaction ID],
--    [Description]
--FROM
--    fn_dblog (NULL, NULL)
--WHERE [Current LSN] = '00A5D5D8:0007C6CB:0001'
--select * from sys.dm_repl_traninfo

EXECUTE sys.sp_cdc_help_change_data_capture

--EXEC sys.sp_cdc_help_jobs;


