
SELECT top 52
     autos.start_time
   , ag.name
   , db.database_name
   , autos.current_state
   , autos.performed_seeding
   , autos.failure_state
   , autos.failure_state_desc
FROM
     sys.dm_hadr_automatic_seeding AS autos
JOIN sys.availability_databases_cluster AS db
    ON autos.ag_db_id = db.group_database_id
JOIN sys.availability_groups AS ag
    ON autos.ag_id = ag.group_id
WHERE
     autos.start_time > DATEADD(DAY, -2, GETDATE()) 
ORDER BY
     autos.start_time DESC;


SELECT
    --local_physical_seeding_id
  --, remote_physical_seeding_id
  --, local_database_id
   local_database_name
  , remote_machine_name
  , role_desc
  , internal_state_desc
  , transfer_rate_bytes_per_second transfer_rate_bytes_per_second
  , transferred_size_bytes/1024/1024 transferred_size_MB
  , database_size_bytes/1024/1024 database_size_MB
  , cast((transferred_size_bytes / cast(database_size_bytes as decimal(19,2))) * 100 as money) PcentDone
  , start_time_utc
  --, end_time_utc
  , estimate_time_complete_utc
  , total_disk_io_wait_time_ms
  , total_network_wait_time_ms
  --, failure_code
  --, failure_message
  --, failure_time_utc
  , is_compression_enabled
FROM
    sys.dm_hadr_physical_seeding_stats 
	where end_time_utc is null 
	ORDER BY start_time_utc DESC;


--	RAISERROR (
--		'Hold on half a min!'
--		, 0
--		, 0
--		);

--WAITFOR DELAY '00:00:30'
--GO 10


/*
dbcc traceon (9567,-1)

ALTER AVAILABILITY GROUP ag01 
    MODIFY REPLICA ON 'dbstage2' 
    WITH (SEEDING_MODE = AUTOMATIC)

*/