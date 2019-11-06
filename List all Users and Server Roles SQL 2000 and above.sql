

if @@Version like 'Microsoft SQL Server  2000%'  
SELECT name
	  ,Case when isntname + isntgroup > 0 
			then 'WINDOWS_LOGIN' 
			Else 'SQL_LOGIN' end as Type_Desc 
	  ,ServerRole as [role]
  FROM [master].[dbo].[syslogins] s
  left join (
		select 'sysadmin' ServerRole, loginname from [master].[dbo].[syslogins] where sysadmin = 1
		union
		select 'securityadmin', loginname from [master].[dbo].[syslogins] where securityadmin = 1
		union
		select 'serveradmin', loginname from [master].[dbo].[syslogins] where serveradmin = 1
		union
		select 'setupadmin', loginname from [master].[dbo].[syslogins] where setupadmin = 1
		union
		select 'processadmin', loginname from [master].[dbo].[syslogins] where processadmin = 1
		union
		select 'diskadmin', loginname from [master].[dbo].[syslogins] where diskadmin = 1
		union
		select 'dbcreator', loginname from [master].[dbo].[syslogins] where dbcreator = 1
		union
		select 'bulkadmin', loginname from [master].[dbo].[syslogins] where bulkadmin = 1
) r on 	s.LoginName = r.LoginName  
  
  order by name
  else 
  SELECT PRN.name,
Prn.Type_Desc,
srvrole.name AS [role]
FROM master.sys.server_role_members membership 
INNER JOIN (SELECT * FROM master.sys.server_principals  WHERE type_desc='SERVER_ROLE') srvrole 
ON srvrole.Principal_id= membership.Role_principal_id 
RIGHT JOIN master.sys.server_principals  PRN ON PRN.Principal_id= membership.member_principal_id 
WHERE Prn.Type_Desc NOT IN ('SERVER_ROLE') 
AND PRN.is_disabled =0
AND (Prn.Type_Desc = 'WINDOWS_LOGIN' OR Prn.Type_Desc = 'SQL_LOGIN')
order by prn.name,Prn.type_desc 

  
