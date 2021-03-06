/****** Object:  StoredProcedure [dbo].[usp_DBA_Get_TempDBUsageBySession_ExecSessions]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_DBA_Get_TempDBUsageBySession_ExecSessions]
AS
SELECT 
	[s].[session_id]
	--,[d].[percent_complete]
	,ISNULL([p].[hostname],'') AS [hostname]
	,ISNULL([p].[program_name],'') AS [program_name]
	,ISNULL([p].[cmd],'') AS [cmd]
	,ISNULL([p].[loginame],'') AS [loginame]
	,[s].[last_request_start_time]
	,[s].[last_request_end_time]
	,ISNULL([t].[text],'') AS [text]
	,[u].[user_objects_alloc_page_count]
	,[u].[user_objects_dealloc_page_count]
	,[u].[internal_objects_alloc_page_count]
	,[u].[internal_objects_dealloc_page_count]
	,[s].[memory_usage]
	,[s].[reads]
	,[s].[writes]
	,[s].[logical_reads]
	,[s].[row_count]
	,GETDATE() AS [CollectionTime]
FROM [sys].[sysprocesses] [p]
CROSS APPLY [sys].[dm_exec_sql_text]([p].[sql_handle]) AS [t]
LEFT JOIN [sys].[dm_exec_sessions] [s] ON [p].[spid] = [s].[session_id]
LEFT JOIN [sys].[dm_db_session_space_usage] [u] ON [p].[spid] = [u].[session_id]
WHERE ([s].[session_id] > 50)
ORDER BY [u].[internal_objects_alloc_page_count] + [u].[user_objects_alloc_page_count] DESC;

GO
