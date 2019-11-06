/*

XE - Monitor SA

	2012 + version
	2008 version

*/
-- 2012 +
CREATE EVENT SESSION [MonitorSA] ON SERVER
ADD EVENT sqlserver.sql_statement_completed (
    ACTION ( sqlserver.client_app_name, sqlserver.client_hostname,
    sqlserver.database_name, sqlserver.nt_username, sqlserver.sql_text,
    sqlserver.username )
    WHERE ( [sqlserver].[username] = N'sa' ) ) -- CHANGE TO LOGIN YOU WANT TO MONITOR
ADD TARGET package0.event_file ( SET filename = N'c:\temp\MonitorSA.xel',
    METADATAFILE = N'c:\temp\MonitorSA.xem' )
GO

ALTER EVENT SESSION MonitorSA ON SERVER
  STATE = START;
GO


/*

-- Read Results 

*/

SELECT  xdata.value('(event[@name="sql_statement_completed"]/@timestamp)[1]',
                    'datetime') [Execution_Time] ,
        xdata.value('(/event/action[@name="username"]/value)[1]',
                    'varchar(100)') AS [User] ,
        xdata.value('(/event/action[@name="client_hostname"]/value)[1]',
                    'varchar(100)') AS [ClientHost] ,
        xdata.value('(/event/action[@name="client_app_name"]/value)[1]',
                    'varchar(100)') AS [ClientApplication] ,
        xdata.value('(/event/action[@name="database_name"]/value)[1]',
                    'varchar(100)') AS [Database] ,
        xdata.value('(/event/action[@name="sql_text"]/value)[1]',
                    'varchar(max)') AS [SQLText]
FROM    ( SELECT    CAST(event_data AS XML)
          FROM      sys.fn_xe_file_target_read_file('C:\Temp\MonitorSA*.xel',
                                                    NULL, NULL, NULL)
        ) AS xmlr ( xdata )
ORDER BY xdata.value('(event[@name="sql_statement_completed"]/@timestamp)[1]',
                     'datetime') DESC;




/*

-- SQL Server 2008 CREATE



CREATE EVENT SESSION [MonitorSA] ON SERVER
ADD EVENT sqlserver.sql_statement_completed (
    ACTION ( sqlserver.client_app_name, sqlserver.client_hostname,
    sqlserver.database_id, sqlserver.nt_username, sqlserver.sql_text,
    sqlserver.username )
    WHERE ( [sqlserver].[username] = N'sa' ) ) -- CHANGE TO LOGIN YOU WANT TO MONITOR
  ADD TARGET package0.asynchronous_file_target( SET filename = N'c:\temp\MonitorSAr2.xel', 
      METADATAFILE = N'c:\temp\MonitorSA.xem' )
GO

ALTER EVENT SESSION MonitorSA ON SERVER
  STATE = START;
GO




-- SQL Server 2008 Query


SELECT  xdata.value('(event[@name="sql_statement_completed"]/@timestamp)[1]',
                    'datetime') [Execution_Time] ,
        xdata.value('(/event/action[@name="username"]/value)[1]',
                    'varchar(100)') AS [User] ,
        xdata.value('(/event/action[@name="client_hostname"]/value)[1]',
                    'varchar(100)') AS [ClientHost] ,
        xdata.value('(/event/action[@name="client_app_name"]/value)[1]',
                    'varchar(100)') AS [ClientApplication] ,
        DB_NAME(xdata.value('(/event/action[@name="database_id"]/value)[1]',
                    'int')) AS [Database] ,
        xdata.value('(/event/action[@name="sql_text"]/value)[1]',
                    'varchar(max)') AS [SQLText]
FROM    ( SELECT    CAST(event_data AS XML)
          FROM      sys.fn_xe_file_target_read_file('C:\Temp\MonitorSAr2*.xel','c:\temp\MonitorSA*.xem', NULL, NULL)
        ) AS xmlr ( xdata )
ORDER BY xdata.value('(event[@name="sql_statement_completed"]/@timestamp)[1]',
                     'datetime') DESC;

*/


