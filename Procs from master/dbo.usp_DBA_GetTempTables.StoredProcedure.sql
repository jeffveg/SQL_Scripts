/****** Object:  StoredProcedure [dbo].[usp_DBA_GetTempTables]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[usp_DBA_GetTempTables]
AS
DECLARE @FileName VARCHAR(MAX)  

SELECT @FileName = SUBSTRING(path, 0,
   LEN(path)-CHARINDEX('\', REVERSE(path))+1) + '\Log.trc'  
FROM sys.traces   
WHERE is_default = 1;  

SELECT   
     gt.SPID AS [session_id],
     ISNULL(gt.HostName,'') AS [hostname],  
	 o.name AS [objectname],   
     o.OBJECT_ID AS [objectID],  
     o.create_date, 
     ISNULL(gt.NTUserName,'') AS [loginame],  
     ISNULL(gt.DatabaseName,'') AS [database],  
     ISNULL(gt.TEXTData,'') AS [text]
	 ,gt.ObjectName AS [objname]
	 ,gt.TransactionID AS [transid]
FROM sys.fn_trace_gettable( @FileName, DEFAULT ) AS gt  
JOIN tempdb.sys.objects AS o   
     ON gt.ObjectID = o.OBJECT_ID  
WHERE gt.DatabaseID = 2 
  AND gt.EventClass = 46 -- (Object:Created Event from sys.trace_events)  
  AND o.create_date >= DATEADD(ms, -100, gt.StartTime)   
  AND o.create_date <= DATEADD(ms, 100, gt.StartTime);


GO
