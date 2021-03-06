/****** Object:  StoredProcedure [dbo].[usp_DBA_Get_TempDBUsageBySession_ExecRequests]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_DBA_Get_TempDBUsageBySession_ExecRequests]
AS
SELECT 
	[s].[spid] AS [session_id]
	--,[d].[percent_complete]
	,ISNULL([s].[hostname],'') AS [hostname]
	,ISNULL([s].[program_name],'') AS [program_name]
	,ISNULL([s].[cmd],'') AS [cmd]
	,ISNULL([s].[loginame],'') AS [loginame]
	,[s].[login_time]
	,ISNULL([t].[text],'') AS [text]
	,[u].[user_objects_alloc_page_count]
	,[u].[user_objects_dealloc_page_count]
	,[u].[internal_objects_alloc_page_count]
	,[u].[internal_objects_dealloc_page_count]
	,ISNULL([d].[granted_query_memory],'') AS [granted_query_memory]
	,ISNULL([d].[reads],'') AS [reads]
	,ISNULL([d].[writes],'') AS [writes]
	,ISNULL([d].[logical_reads],'') AS [logical_reads]
	,ISNULL([d].[row_count],'') AS [row_count]
	,GETDATE() AS [CollectionTime]
FROM [sys].[sysprocesses] [s]
CROSS APPLY [sys].[dm_exec_sql_text]([s].[sql_handle]) AS [t]
LEFT JOIN [sys].[dm_exec_requests] [d] ON [s].[spid] = [d].[session_id]
LEFT JOIN [sys].[dm_db_session_space_usage] [u] ON [s].[spid] = [u].[session_id]
ORDER BY [u].[internal_objects_alloc_page_count] + [u].[user_objects_alloc_page_count] DESC;

GO
