/****** Object:  StoredProcedure [dbo].[usp_DBA_Get_TempDBUsageBySession_Totals]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_DBA_Get_TempDBUsageBySession_Totals]
AS
SELECT  session_id ,
        CONVERT(DECIMAL(12, 2), ROUND(s.user_objects_alloc_page_count * 8.
                                      / 1024, 2)) AS user_objects_alloc_page_count ,
        CONVERT(DECIMAL(12, 2), ROUND(s.user_objects_dealloc_page_count * 8.
                                      / 1024, 2)) AS user_objects_dealloc_page_count ,
        CONVERT(DECIMAL(12, 2), ROUND(s.internal_objects_alloc_page_count * 8.
                                      / 1024, 2)) AS internal_objects_alloc_page_count ,
        CONVERT(DECIMAL(12, 2), ROUND(s.internal_objects_dealloc_page_count
                                      * 8. / 1024, 2)) AS internal_objects_dealloc_page_count ,
        CONVERT(DECIMAL(12, 2), ROUND(( s.internal_objects_dealloc_page_count
                                        + s.internal_objects_alloc_page_count
                                        + s.user_objects_dealloc_page_count
                                        + s.user_objects_alloc_page_count )
                                      * 8. / 1024, 2)) AS TotalMB
		,GETDATE() AS [CollectionTime]
FROM    sys.dm_db_session_space_usage s
WHERE   session_id > 50
        AND ( s.internal_objects_dealloc_page_count
              + s.internal_objects_alloc_page_count
              + s.user_objects_dealloc_page_count
              + s.user_objects_alloc_page_count ) > 0
ORDER BY TotalMB DESC;
GO
