USE [master]
GO
CREATE CREDENTIAL [Credential_svcSQLJob] WITH IDENTITY = N'ntbank\svcSQLSSIS', SECRET = N'<PutPasswordHere>'
Print 'Credental Credential_svcSQLJob Created'
GO

USE [msdb]
GO
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'Proxy_svcSQLJobs',@credential_name=N'Credential_svcSQLJob', 
		@enabled=1
Print 'Proxy Proxy_svcSQLJobs Created'
GO

EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'Proxy_svcSQLJobs', @subsystem_id=11
Print 'Proxy granted SSIS execuition'
GO


EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'Proxy_svcSQLJobs', @login_name=N'NTBANK\svcSQLJob'
Print 'Proxy login granted to NTBANK\svcSQLJob'
GO


/*

-- Change password for svcSQSSIS here


USE [master]
GO
ALTER CREDENTIAL [Credential_svcSQLJob] WITH IDENTITY = N'ntbank\svcSQLSSIS', SECRET = N'<PutNewPasswordHere>'
Print 'Password for Credential_svcSQLJob using account ntbank\svcSQLSSIS changed' 
GO
*/