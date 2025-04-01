Set nocount on
Declare @Sep char(159) 
set @Sep = '*****************************************************************************************************************************************************'
Print 'SQL Server Services > Check that correct account is running SQL Server Engine and Agent:
o   Prod: CLNT\sys_prodsql
o   QA: CLNT\sys_qasql
o   DEV: CLNT\sys_devsql

'

Declare @service_account table ( ServiceName varchar(40), service_account varchar(30),Results varchar(30))
Insert into @service_account
SELECT 
	 servicename
	,service_account
	,case service_account 
		when 'CLNT\sys_prodsql' then 'Prod' 
		when 'CLNT\sys_qasql' then 'QA' 
		when 'CLNT\sys_devsql' then 'Dev'
		else '**ERROR** Undifined User'
	end as Results
FROM sys.dm_server_services
where servicename in ('SQL Server (MSSQLSERVER)','SQL Server Agent (MSSQLSERVER)')

Select * from @service_account


Print @Sep + '
Check SQL Engine and SQL Agent are set to Automatic Start Mode 

'
Declare @service_startup table ( ServiceName varchar(40), startup_type_desc varchar(30),Results varchar(30))
Insert into @service_startup
SELECT 
	 servicename
	,startup_type_desc
	,case startup_type
		when 2 then 'Correct, set to Automatic' 
		else '**ERROR** Not set to Automatic'
	end as Results
FROM sys.dm_server_services
where servicename in ('SQL Server (MSSQLSERVER)','SQL Server Agent (MSSQLSERVER)')

select * from @service_startup

Print @Sep + '
Startup Parameters
o   Remove trace flags 1117 and 1118
o   Add trace flags 3226 (don’t log successful backups)

'
declare @TraceFlags table (TraceFlag int, FlagStatus bit, GlobalStatus bit, SessionStatus bit)
Insert into @TraceFlags
exec ('dbcc tracestatus (1117,1118,3226)')

Select 
	 TraceFlag
	,GlobalStatus
	,case 
		when TraceFlag = 1117 and GlobalStatus = 0 then 'Correct' 
		when TraceFlag = 1118 and GlobalStatus = 0 then 'Correct' 
		when TraceFlag = 3226 and GlobalStatus = 1 then 'Correct' 
		Else '***ERROR*** Not set correctly'
	end as Results
from @TraceFlags

Print @Sep + '
SQL Server Network Configuration
	o   Protocols for MSSQLSERVER
		§  Double click - All should be enabled

'
SELECT 'Named Pipes' AS [Protocol],cast( value_data as bit) Value_Data, iif(value_data = 1, 'Yes - Correct', '***ERROR*** - No') AS Results
FROM sys.dm_server_registry
WHERE registry_key LIKE '%np' AND value_name = 'Enabled'
UNION
SELECT 'Shared Memory', cast( value_data as bit) Value_Data,iif(value_data = 1, 'Yes - Correct', '***ERROR*** - No')
FROM sys.dm_server_registry
WHERE registry_key LIKE '%sm' AND value_name = 'Enabled'
UNION
SELECT 'TCP/IP',cast( value_data as bit) Value_Data, iif(value_data = 1, 'Yes - Correct', '***ERROR*** - No')
FROM sys.dm_server_registry
WHERE registry_key LIKE '%tcp' AND value_name = 'Enabled'

Print @Sep + '
SQL Server Network Configuration
	o   Protocols for MSSQLSERVER
		§  Right click on Protocols > Properties > Force Encryption > Yes 

'
DECLARE @EncryptionForced INT
EXEC xp_instance_regread 'HKEY_LOCAL_MACHINE', 'Software\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib', 'ForceEncryption', @EncryptionForced OUTPUT
SELECT CASE WHEN @EncryptionForced = 1 THEN 'Correct - Encryption Forced = Yes ' ELSE '***ERROR*** - Encryption Forced = No' END

Print @Sep + '
SQL Server Network Configuration
	o   Protocols for MSSQLSERVER
		§  Right click on TCP/IP > Properties > IP Addresses > IPALL > TCP Port = 1433, 11433  

	'
SELECT 
	 'TCP Port' as tcpPort
	,cast( value_name as varchar(20)) value_name
	,cast( value_data as varchar(20)) value_data
	,case 
		when value_data = '11433, 1433' then 'Correct'
		when value_data = '1433, 11433' then 'Correct'
		else '***ERROR***'
	end as Results
FROM sys.dm_server_registry 
WHERE registry_key LIKE '%IPALL' AND value_name in ('TcpPort')

Print @Sep + '
SQL Native Client 11.0 Configuration
	o   Client Protocols > All should be enabled

'

Declare @Client table (RegKey varchar(50), RegValue Varchar(50), RegData Varchar(50))
Insert into @Client
EXEC xp_regread 'HKEY_LOCAL_MACHINE', 'SOFTWARE\Microsoft\MSSQLServer\Client\SNI11.0', 'ProtocolsSupported'

If (Select count(*) from @Client) = 3  
		Select  RegValue ,'Correct' As Results from @Client
	else 
		Select RegValue, '***ERROR*** - There should be 3 entries' As Results from @Client

Print @Sep + '

==================================================> NOTE This needs to be done manually <====================================================

Server Settings
	Certificate
	o   Start menu (Right Click) > Run > MMC > File > Add Snap In > Certificates > Add > Computer Account > Next>  Finish > OK
		Certificates > Personal > Certificates > Right click on existing cert > All Tasks > ManagePrivate Keys > sys_prodsql should have Read Only permissions

==========================================================> End of manual run  <=============================================================='
Print @Sep + '
Server Settings
	Certificate
		Open SSMS > Check that CLNT\sys_prodsql is sysadmin (Server > Security > Logins > right click on CLNT\sys_prodsql > Properties > Server Roles)
'

select
    cast(rol.name as char(30)) role_name   
   ,cast(mbr.name as char(30)) login_name
   ,case rol.name when 'sysadmin' 
		then 'Correct'
		else '***ERROR*** - User CLNT\sys_prodsql needs to be a sysadmin'
	end as Results
from
   sys.server_role_members srm                                                
   join sys.server_principals rol 
      on srm.role_principal_id   = rol.principal_id  
   join sys.server_principals mbr 
      on srm.member_principal_id = mbr.principal_id
where mbr.name = 'CLNT\sys_prodsql'; 

Print @Sep + '
Test encryption
o   Run query: SELECT * from sys.dm_exec_connections. ENCRYPT_OPTION should be true, for everything but protocol_type = Database Mirroring.'

SELECT 
	protocol_type
	,cast( encrypt_option as char(10)) as encrypt_option
	,case 
		when protocol_type = 'Database Mirroring' and encrypt_option = 'FALSE' 
			then 'Correct'
		when encrypt_option = 'True' 
			then 'Correct'
		else '***ERROR*** - Encrytion not working'
	end as Results
from sys.dm_exec_connections
group by protocol_type
	,encrypt_option

Print @Sep + '
Clustering Services
o   If AG required: Server Manager > Tools > Failover Cluster Manager should be available.

'

declare @AGs int
select @AGs = count(*) from sys.availability_groups_cluster 

Select Results = Case when @AGs > 0
	 then 'Correct at lease one AG exists'
		else '***ERROR*** - No AG exists'
	end

Print @Sep + '
Administrators
o   Server Manager > Tools > Computer Management > Local Users and Groups > Groups > Administrators > Should have: DBA, Domain Admins, it-ops-dcim, 

'
declare @Admins table ( role_name char(30), login_name char (30), Results char(80))

Insert into @Admins
select
    cast(rol.name as char(30))    
   ,cast(mbr.name as char(30)) 
   ,case rol.name when 'sysadmin' 
		then 'Correct'
		else '***ERROR*** - User CLNT\sys_prodsql needs to be a sysadmin'
	end 
from
   sys.server_role_members srm                                                
   join sys.server_principals rol 
      on srm.role_principal_id   = rol.principal_id  
   join sys.server_principals mbr 
      on srm.member_principal_id = mbr.principal_id
where rol.name = 'sysadmin' and mbr.name in ('CLNT\it-ops-dcim','CLNT\DBA','clnt-azu-admin')

If (Select count(*) from @Admins) = 3  
		Select  'Correct' As Results
	else 
		Select '***ERROR*** - There should be 3 entries' 

Select * from @Admins

Print @Sep + '
==================================================> NOTE This needs to be done manually <====================================================
MSDTC
	o   Server Manager > Tools > Component Services > Computers > My Computer > Distributed Transaction Coordinator > Local DTC > Right click > Properties > Security Tab
	o   Selected:
		§  Network DTC Access
		§  Allow Inbound
		§  Allow Outbound
		§  No Authentication
		§  Enable XA Transactions
		§  Enable SNA LU 6.2 Transactions

==========================================================> End of manual run  <=============================================================='
Print @Sep + '
SQL Server Folder Paths:
  F: 
	§  backups (a node only)
	§  SQLData
	§  SQLData_Blob
	§  SQLData_CDC
	§  SQLData_History

'
Declare @CMD varchar(2000)
Declare @DIR table(directory varchar(2000))
Declare @Paths table ( directory char(30), results char(50))
set @CMD = 'dir /b F:'

insert into @Paths values
('backups',  '***ERROR*** - May Not exist on b node')
,('SQLData', '***ERROR*** - Missing')
,('SQLData_Blob', '***ERROR*** - Missing')
,('SQLData_CDC', '***ERROR*** - Missing')
,('SQLData_History', '***ERROR*** - Missing')

insert into @DIR
exec xp_cmdshell @CMD

Update p set results =  'Yes - Correct'
from @Paths p join @DIR d on d.directory = p.directory

Select * from @Paths

Print @Sep + '
SQL Server Folder Paths:  
  G:
	§  SQLLogs 
'
delete @Paths 
set @CMD = 'dir /b G:'

insert into @Paths values
('SQLLogs',  '***ERROR*** - Missing')

insert into @DIR
exec xp_cmdshell @CMD

Update p set results =  'Yes - Correct'
from @Paths p join @DIR d on d.directory = p.directory

Select * from @Paths
Print @Sep + '
SQL Server Folder Paths:
D:
	§  SQLData_TempDB  OR

'

delete @Paths 
set @CMD = 'dir /b D:'

insert into @Paths values
('SQLData_TempDB',  '***ERROR*** - Missing')

insert into @DIR
exec xp_cmdshell @CMD

Update p set results =  'Yes - Correct'
from @Paths p join @DIR d on d.directory = p.directory

Select * from @Paths

Print @Sep + '
SQL Server Folder Paths:
H:
	§  SQLData_TempDB

'

delete @Paths 
set @CMD = 'dir /b H:'

insert into @Paths values
('SQLData_TempDB',  '***ERROR*** - Missing')

insert into @DIR
exec xp_cmdshell @CMD

Update p set results =  'Yes - Correct'
from @Paths p join @DIR d on d.directory = p.directory

Select * from @Paths


Print @Sep + '
SQL Server Settings
	Right click on Server > Properties > Memory > Max Memory – 48000 90% of available memory (General > Memory * 0.90 = Memory > Maximum server memory (in MB))

'
Declare @SQLMem money
Declare @ServerMem money
Declare @MemPcent smallmoney

SELECT @SQLMem = cast( [value] as money) 
FROM sys.configurations
WHERE [name] = 'max server memory (MB)' 

SELECT @ServerMem = physical_memory_kb /1024.00
FROM sys.dm_os_sys_info;

set @MemPcent = (@SQLMem/@ServerMem) * 100

Select 
	 @ServerMem as Server_Mem_KB
	,@SQLMem as SQL_Mem_KB 
	,@MemPcent as Pcent_SQL_Use
	,case 
		when @MemPcent Between 80 and 91 
			then 'Correct'
		else	
			 '***ERROR*** - Memory setting out of bounds'
	end as results

Print @Sep + '
SQL Server Settings
	Advanced > MAX DOP (degree of parallelism) – Half of core count

'
Declare @Par money
Declare @NumCore money

select @Par =  cast( [value] as money)  
FROM sys.configurations 
where name = 'max degree of parallelism'

select @NumCore = cpu_count from
sys.dm_os_sys_info

Select 
	 @NumCore as Num_Cores
	,@Par as Max_Deg_Par
	,case 
		when @NumCore/2 =  @Par
			then 'Correct'
		else	
			 '***ERROR*** - Max degree of parallelism not set to 1/2 of Core Count' 
	end as results

Print @Sep + '
SQL Server Settings
	Server > Databases > System Databases > tempdb > Properties > Files - TempDB Configuration – D: Drive, equal to half core count + 1 (log), 64gb autogrow

'
select 
	  CASE
		WHEN groupid = 0
			THEN 'Log'
	    ELSE 'Data'
	 END as FileTypes
	,NumOfFiles 
	,case 
		when groupid = 0 and NumOfFiles = 1 
			THEN 'Correct'
		when  groupid = 1 and ( NumOfFiles = 8  or NumOfFiles = ( @NumCore /2))
			THEN 'Correct'
		ELSE '***ERROR*** number of TempDB logfiles is incorrect'
	end as results
from (
select 
	 groupid 
	,count(*) NumOfFiles   
	from tempdb.sys.sysfiles 
	group by groupid 
) a

Print @Sep + '
SQL Server Settings
	Always On High Availability > Availability Groups > server ag > Availability Group Listeners - Internal and External Listener (ex.: cloud01/prodsql02lst)
Test connection to both listeners (note: on b-node connecting to cloud listener is not required)

'
declare @Listeners table ( dns_name varchar(20), ip_configuration_string_from_cluster char(35), Results char(40)) 
declare @ServerNumber varchar(20) = substring( @@servername, len(@@servername) -2,2)
insert into @Listeners
select 
	 dns_name
	,ip_configuration_string_from_cluster
	,'***ERROR*** - Check name of listener' 
from sys.availability_group_listeners

If (Select count(*) from @Listeners) = 2 
	Select 'Correct' as Listener_Number
else
	Select '***ERROR*** Number of listeners shoud be 2' as Listener_Number

Update @Listeners set Results = 'Correct' where dns_name like '%' + @ServerNumber + '%'
select * from @Listeners  