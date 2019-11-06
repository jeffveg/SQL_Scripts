sp_whoisactive

SELECT cmd,* from sys.sysprocesses
where blocked > 0
AND spid IN (72,64)


SELECT
t1.resource_type,
t1.resource_database_id,
t1.resource_associated_entity_id,
t1.request_mode,
t1.request_session_id,
t2.blocking_session_id,
o1.name 'object name',
o1.type_desc 'object descr',
p1.partition_id 'partition id',
p1.rows 'partition/page rows',
a1.type_desc 'index descr',
a1.container_id 'index/page container_id'
FROM sys.dm_tran_locks as t1
INNER JOIN sys.dm_os_waiting_tasks as t2
	ON t1.lock_owner_address = t2.resource_address
LEFT OUTER JOIN sys.objects o1 on o1.object_id = t1.resource_associated_entity_id
LEFT OUTER JOIN sys.partitions p1 on p1.hobt_id = t1.resource_associated_entity_id
LEFT OUTER JOIN sys.allocation_units a1 on a1.allocation_unit_id = t1.resource_associated_entity_id

--SELECT *, OBJECT_NAME(p.object_id) 
--FROM sys.dm_tran_locks l    
--JOIN sys.partitions p 
--ON l.resource_associated_entity_id = p.hobt_id  
--WHERE l.resource_associated_entity_id = 72057594799652864