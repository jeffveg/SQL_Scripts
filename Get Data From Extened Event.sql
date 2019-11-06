WITH XMLData
AS ( SELECT
         CONVERT(XML, f.event_data) AS event_data
     --,CAST(f.event_data AS XML)  AS [Event-Data-Cast-To-XML]  -- Optional
     FROM
         sys.fn_xe_file_target_read_file(
                                            'S:\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\AppLogin_*.xel'
                                          , NULL
                                          , NULL
                                          , NULL
                                        ) AS f )
SELECT
    XMLData.event_data.value(N'(event/action[@name="server_instance_name"]/value)[1]', N'Varchar(200)') AS SQLServerName
  , COALESCE(
                XMLData.event_data.value(N'(event/action[@name="server_principal_name"]/value)[1]', N'Varchar(200)')
              , XMLData.event_data.value(
                                            N'(event/action[@name="session_server_principal_name"]/value)[1]'
                                          , N'Varchar(200)'
                                        )
            ) AS UserName
  , XMLData.event_data.value(N'(event/action[@name="client_hostname"]/value)[1]', N'Varchar(200)') AS client_hostname
  , XMLData.event_data.value(N'(event/action[@name="client_app_name"]/value)[1]', N'Varchar(200)') AS client_app_name
  , XMLData.event_data.value(N'(event/action[@name="client_pid"]/value)[1]', N'Varchar(200)') AS client_pid
  , XMLData.event_data.value(N'(event/action[@name="database_name"]/value)[1]', N'Varchar(200)') AS database_name
INTO
    #TempData
FROM
    XMLData
WHERE
    XMLData.event_data.value(N'(event/action[@name="server_instance_name"]/value)[1]', N'Varchar(200)') IS NOT NULL;



SELECT DISTINCT
       SQLServerName
     , UserName
     , client_hostname
     , client_app_name
     --, client_pid
     , database_name
FROM
       #TempData;

	   DROP TABLE #TempData