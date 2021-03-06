/****** Object:  StoredProcedure [dbo].[usp_DBA_TempDB_TrackTDriveSize]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_DBA_TempDB_TrackTDriveSize] 
AS
SET NOCOUNT ON;

SELECT DISTINCT 
	--'Database' = DB_NAME([f].[database_id])
	'Drive' = LEFT([vsw].[volume_mount_point],5)
	,'FreeSpaceMB' = CONVERT(INT,[vsw].[available_bytes]/1048576.0) 
	,GETDATE() AS [CollectionTime]
FROM [sys].[master_files] (NOLOCK) [f] 
CROSS APPLY [sys].[dm_os_volume_stats]([f].[database_id], [f].[file_id]) vsw
WHERE (LEFT([vsw].[volume_mount_point],1) = 'T');
GO
