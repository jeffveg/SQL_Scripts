
SELECT es.host_name
	, es.login_name
	, es.program_name
	, st.dbid AS QueryExecContextDBID
	, DB_NAME(st.dbid) AS QueryExecContextDBNAME
	, st.objectid AS ModuleObjectId
	, plan_handle
	, SUBSTRING(st.TEXT, er.statement_start_offset / 2 + 1, (
			CASE 
				WHEN er.statement_end_offset = - 1
					THEN LEN(CONVERT(NVARCHAR(max), st.TEXT)) * 2
				ELSE er.statement_end_offset
				END - er.statement_start_offset
			) / 2) AS Query_Text
	, tsu.session_id
	, tsu.request_id
	, tsu.exec_context_id
	, (tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count) AS OutStanding_user_objects_page_counts
	, (tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) AS OutStanding_internal_objects_page_counts
	, er.start_time
	, er.command
	, er.open_transaction_count
	, er.percent_complete
	, er.estimated_completion_time
	, er.cpu_time
	, er.total_elapsed_time
	, er.reads
	, er.writes
	, er.logical_reads
	, er.granted_query_memory
FROM sys.dm_db_task_space_usage tsu
INNER JOIN sys.dm_exec_requests er
	ON (
			tsu.session_id = er.session_id
			AND tsu.request_id = er.request_id
			)
INNER JOIN sys.dm_exec_sessions es
	ON (tsu.session_id = es.session_id)
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) st
WHERE (tsu.internal_objects_alloc_page_count + tsu.user_objects_alloc_page_count) > 0
ORDER BY (tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count) + (tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) DESC
