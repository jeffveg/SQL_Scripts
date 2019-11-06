--KILL 254

go
sp_WhoIsActive; 
--select * from sys.dm_exec_query_memory_grants 
--select * from sys.dm_exec_query_resource_semaphores


SELECT  SUM(mg.granted_memory_kb) / 1024 / 1024.0 AS granted_memory_gb
FROM    sys.dm_exec_query_memory_grants AS mg
OPTION  ( MAXDOP 1 );

SELECT  mg.granted_memory_kb / 1024 AS granted_memory_mb
,mg.ideal_memory_kb / 1024  AS Ideal_Memory_MB,mg.used_memory_kb/1024 used_memory_mb
       ,mg.session_id
       ,t.text
       ,qp.query_plan
FROM    sys.dm_exec_query_memory_grants AS mg
CROSS APPLY sys.dm_exec_sql_text(mg.sql_handle) AS t
CROSS APPLY sys.dm_exec_query_plan(mg.plan_handle) AS qp
ORDER BY 1 DESC
OPTION  ( MAXDOP 1 );

--SELECT * FROM sys.dm_exec_sql_text(0x06002C00C9659F21B0BD45781401000001000000000000000000000000000000000000000000000000000000)
--SELECT * FROM sys.dm_exec_sql_text(0x06002C0066391C2AF061D9191101000001000000000000000000000000000000000000000000000000000000)
--SELECT * FROM sys.dm_exec_sql_text(0x06002C00933BDC2320C409A01E01000001000000000000000000000000000000000000000000000000000000)

--SELECT * FROM sys.dm_exec_query_plan(0x06002C00C9659F21B0BD45781401000001000000000000000000000000000000000000000000000000000000) 
--SELECT * FROM sys.dm_exec_query_plan(0x06002C0066391C2AF061D9191101000001000000000000000000000000000000000000000000000000000000) 
--SELECT * FROM sys.dm_exec_query_plan(0x06002C00933BDC2320C409A01E01000001000000000000000000000000000000000000000000000000000000) 
 

-- 26,785,040
