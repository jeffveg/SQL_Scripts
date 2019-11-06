SELECT  FreePages = SUM(unallocated_extent_page_count)
      , FreeSpaceMB = SUM(unallocated_extent_page_count) / 128.0
      , VersionStorePages = SUM(version_store_reserved_page_count)
      , VersionStoreMB = SUM(version_store_reserved_page_count) / 128.0
      , InternalObjectPages = SUM(internal_object_reserved_page_count)
      , InternalObjectsMB = SUM(internal_object_reserved_page_count) / 128.0
      , UserObjectPages = SUM(user_object_reserved_page_count)
      , UserObjectsMB = SUM(user_object_reserved_page_count) / 128.0
FROM    sys.dm_db_file_space_usage ;


WITH    Tasks
          AS (SELECT    session_id
                      , wait_type
                      , wait_duration_ms
                      , blocking_session_id
                      , resource_description
                      , PageID = CAST(RIGHT(resource_description,
                                            LEN(resource_description)
                                            - CHARINDEX(':',
                                                        resource_description,
                                                        3)) AS INT)
              FROM      sys.dm_os_waiting_tasks
              WHERE     wait_type LIKE 'PAGE%LATCH_%'
                        AND resource_description LIKE '2:%')
    SELECT  session_id
          , wait_type
          , wait_duration_ms
          , blocking_session_id
          , resource_description
          , ResourceType = CASE WHEN PageID = 1
                                     OR PageID % 8088 = 0 THEN 'Is PFS Page'
                                WHEN PageID = 2
                                     OR PageID % 511232 = 0 THEN 'Is GAM Page'
                                WHEN PageID = 3
                                     OR (PageID - 1) % 511232 = 0
                                THEN 'Is SGAM Page'
                                ELSE 'Is Not PFS, GAM, or SGAM page'
                           END
    FROM    Tasks ;
    
    
SELECT  *
FROM    sys.dm_os_waiting_tasks
    
SELECT  *
FROM    sys.dm_exec_query_memory_grants
    
USE tempdb ;
SELECT  ObjectName = OBJECT_NAME(object_id)
      , object_id
      , index_id
      , allocation_unit_id
      , used_pages
      , AU.type_desc
FROM    sys.allocation_units AS AU
        INNER JOIN sys.partitions AS P
            -- Container is hobt for in row data
-- and row overflow data
            ON AU.container_id = P.hobt_id
-- IN_ROW_DATA and ROW_OVERFLOW_DATA
               AND AU.type IN (1, 3)
UNION ALL
SELECT  ObjectName = OBJECT_NAME(object_id)
      , object_id
      , index_id
      , allocation_unit_id
      , used_pages
      , AU.type_desc
FROM    sys.allocation_units AS AU
        INNER JOIN sys.partitions AS P
            -- Container is partition for LOB data
            ON AU.container_id = P.partition_id
-- LOB_DATA
               AND AU.type = 2
               
               
SELECT  object_name AS 'Counter Object'
      , [Version Generation rate (KB/s)]
      , [Version Cleanup rate (KB/s)]
      , [Version Store Size (KB)]
FROM    (SELECT object_name
              , counter_name
              , cntr_value
         FROM   sys.dm_os_performance_counters
         WHERE  object_name = 'SQLServer:Transactions'
                AND counter_name IN ('Version Generation rate (KB/s)',
                                     'Version Cleanup rate (KB/s)',
                                     'Version Store Size (KB)')) AS P PIVOT ( MIN(cntr_value) FOR counter_name IN ([Version Generation rate (KB/s)],
                                                              [Version Cleanup rate (KB/s)],
                                                              [Version Store Size (KB)]) ) AS Pvt ;