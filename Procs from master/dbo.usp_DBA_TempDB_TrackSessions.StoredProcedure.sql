/****** Object:  StoredProcedure [dbo].[usp_DBA_TempDB_TrackSessions]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_DBA_TempDB_TrackSessions] 
AS 
SET NOCOUNT ON;

SELECT TOP 25
    [s].[session_id]
    ,[d].[name] AS [database]
	,[s].[host_name]
    ,[s].[program_name]
	,[s].[client_interface_name]
	,[s].[login_time]
	,[s].[last_request_start_time]
	,[s].[last_request_end_time]
    ,[s].[login_name]
	,[s].[status]
    ,[s].[cpu_time]
    ,[s].[total_scheduled_time]
	,[s].[total_elapsed_time]
    ,([s].[memory_usage] * 8) AS [MemoryUsageKB]
	,([su].[user_objects_alloc_page_count] * 8) AS [UserAllocatedSpaceKB]
	,([su].[user_objects_dealloc_page_count] * 8) AS [UserDeallocatedSpaceKB]
	,([su].[internal_objects_alloc_page_count] * 8) AS [InternalAllocatedSpaceKB]
	,([su].[internal_objects_dealloc_page_count] * 8) AS [InternalDeallocatedSpaceKB]
	,(([su].[user_objects_alloc_page_count] * 8) + ([su].[user_objects_dealloc_page_count] * 8)) AS [TotalUserObjectsKB] 
	,(([su].[internal_objects_alloc_page_count] * 8) + ([su].[internal_objects_dealloc_page_count] * 8)) AS [TotalInternalObjectsKB]
    ,[s].[is_user_process] /* 1 - User Session, 2 - System Session */
	,[s].[row_count]
	,[s].[total_elapsed_time]
	,[s].[reads]
	,[s].[writes]
	,[s].[logical_reads]
	,GETDATE() AS [CollectionTime]
FROM [sys].[dm_db_session_space_usage] [su]
JOIN [sys].[dm_exec_sessions] [s] ON [su].[session_id] = [s].[session_id]
JOIN [sys].[databases] [d] on [s].[database_id] = [d].[database_id]
ORDER BY 19 DESC;
GO
