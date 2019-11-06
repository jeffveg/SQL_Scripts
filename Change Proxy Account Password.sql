-- Change password for svcSQSSIS here
USE [master]

ALTER CREDENTIAL [Credential_svcSQLJob] WITH IDENTITY = N'ntbank\svcSQLSSIS', SECRET = N'<PutNewPasswordHere>'
Print 'Password for Credential_svcSQLJob using account ntbank\svcSQLSSIS changed' 



DECLARE @Ident NVARCHAR(100)
DECLARE @Pass NVARCHAR(100)

SET @Pass = n''

USE [master]
SELECT @Ident = credential_identity FROM sys.credentials WHERE name = 'Credential_svcSQLJob'


-- Change password for svcSQSSIS here
ALTER CREDENTIAL [Credential_svcSQLJob] WITH IDENTITY = @Ident, SECRET = @Pass
Print 'Password for Credential_svcSQLJob using account ' + @Ident + ' changed' 
