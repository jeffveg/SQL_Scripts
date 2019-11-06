-- If the Event Session Exists, drop it first
IF EXISTS (SELECT 1 
            FROM sys.server_event_sessions 
            WHERE name = 'SQLskills_DatabaseUsage')
    DROP EVENT SESSION [SQLskills_DatabaseUsage] 
    ON SERVER;
 
-- Create the Event Session
CREATE EVENT SESSION [SQLskills_DatabaseUsage] 
ON SERVER 
ADD EVENT sqlserver.lock_acquired( 
    WHERE owner_type = 4 -- SharedXactWorkspace
      AND resource_type = 2 -- Database level lock
      AND database_id > 4 -- non system database
      AND sqlserver.is_system = 0 -- must be a user process
) 
ADD TARGET package0.histogram
( SET slots = 32, -- Adjust based on number of databases in instance
      filtering_event_name='sqlserver.lock_acquired', -- aggregate on the lock_acquired event
      source_type=0, -- event data and not action data
      source='database_id' -- aggregate by the database_id
); -- dispatch immediately and don't wait for full buffers
GO
 
-- Start the Event Session
ALTER EVENT SESSION [SQLskills_DatabaseUsage] 
ON SERVER 
STATE = START;
GO
 
-- Parse the session data to determine the databases being used.
SELECT  slot.value('./@count', 'int') AS [Count] ,
        DB_NAME(slot.query('./value').value('.', 'int')) AS [Database]
FROM
(
    SELECT CAST(target_data AS XML) AS target_data
    FROM sys.dm_xe_session_targets AS t
    INNER JOIN sys.dm_xe_sessions AS s 
        ON t.event_session_address = s.address
    WHERE   s.name = 'SQLskills_DatabaseUsage'
      AND t.target_name = 'histogram') AS tgt(target_data)
CROSS APPLY target_data.nodes('/HistogramTarget/Slot') AS bucket(slot)
ORDER BY slot.value('./@count', 'int') DESC
 
GO