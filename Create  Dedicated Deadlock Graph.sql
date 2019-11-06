CREATE EVENT SESSION [DeadLocks] ON SERVER 
ADD EVENT sqlserver.xml_deadlock_report(
    ACTION(package0.callstack,sqlserver.client_hostname,sqlserver.database_id,sqlserver.database_name,sqlserver.nt_username,sqlserver.plan_handle,sqlserver.sql_text)) 
ADD TARGET package0.event_file(SET filename=N'S:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\DeadLocks.xel',max_file_size=(500),max_rollover_files=(20))
WITH (STARTUP_STATE=ON)
GO


