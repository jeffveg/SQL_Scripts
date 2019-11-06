
SELECT plan_handle,usecounts, cacheobjtype, objtype, size_in_bytes, text, query_plan 
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
CROSS APPLY sys.dm_exec_query_plan(plan_handle)
WHERE usecounts > 1 
AND text LIKE '%CallTransferPremCertUsedRCIV%'
AND objtype = 'Proc'
ORDER BY usecounts DESC;

DBCC FREEPROCCACHE (0x0500290015AB9370803281C20D00000001000000000000000000000000000000000000000000000000000000
)


