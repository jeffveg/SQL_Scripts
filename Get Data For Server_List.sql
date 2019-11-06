
DECLARE @TimeZone VARCHAR(50)
EXEC MASTER.dbo.xp_regread 'HKEY_LOCAL_MACHINE',
'SYSTEM\CurrentControlSet\Control\TimeZoneInformation',
'TimeZoneKeyName',@TimeZone OUT



SELECT 
  @@SERVERNAME AS 'ServerName'
, CONNECTIONPROPERTY('local_net_address')  AS 'ServerIP'
, 1 AS 'UseIP'
, @@SERVICENAME  AS 'ServiceName'
, CONNECTIONPROPERTY('local_tcp_port')  AS 'Port'
,0 UsePort
,0 ISCluster
,NULL Pipe
,0 UsePipe
,NULL Username
,NULL [Password]
,1 UseTrusted
,'TBA' Environment
,1 ActiveFlag
,SERVERPROPERTY('ProductVersion') SQLVersion
,NULL OSVersion
,NULL Notes
,NULL OldName
,NULL PreferredPrimaryHost
,0 IsVirtualName
,1 IsSvcsMonitored
,NULL BackupType
,@TimeZone TimeZone
,NULL BackupPath


