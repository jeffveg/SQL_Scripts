select 
	 name
	,recovery_model_desc 
 from 
	sys.databases 
where 
	name not in ('master','tempdb','model','msdb')
	AND LEFT(CAST(compatibility_level as varchar(3)),LEN(compatibility_level)-1) <> REPLACE(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(2)),'.','')
