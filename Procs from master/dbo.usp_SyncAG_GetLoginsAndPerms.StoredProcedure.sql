/****** Object:  StoredProcedure [dbo].[usp_SyncAG_GetLoginsAndPerms]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_SyncAG_GetLoginsAndPerms]
AS
SET NOCOUNT ON;
SELECT
	[a].[sid]
	,[a].[LoginName]
	,[a].[Statement]
	,[b].[Permissions]
	,[a].[default_database_name]
	,[a].[is_disabled]
	,[a].[create_date]
	,[a].[modify_date]
	,[a].[denylogin]
	,[a].[hasaccess]
	,[a].[language]
FROM (
	SELECT
		[p].[name] AS [LoginName]
		,'IF EXISTS (SELECT [name] FROM [sys].[server_principals] WHERE ([name] = N''' + [p].[name] + ''')) BEGIN DROP LOGIN ' + QUOTENAME([p].[name]) + '; END CREATE LOGIN ' + QUOTENAME([p].[name])
		+ CASE
			WHEN [p].[type] = 'S' THEN ' WITH PASSWORD = ' + CONVERT(NVARCHAR(MAX),[l].[password_hash],1) + ' HASHED, SID = ' + CONVERT(NVARCHAR(MAX),[l].[sid],1) + ', DEFAULT_DATABASE = ' + QUOTENAME([p].[default_database_name]) + ', DEFAULT_LANGUAGE = ' + QUOTENAME([p].[default_language_name])
				+ ', CHECK_POLICY = '
					+ CASE
						WHEN [l].[is_policy_checked] = 1 THEN 'ON'
						ELSE 'OFF'
					END
				+ ', CHECK_EXPIRATION = '
					+ CASE
						WHEN [l].[is_expiration_checked] = 1 THEN 'ON;'
						ELSE 'OFF;'
					END
				+ CASE
					WHEN [p].[is_disabled] = 1 THEN ' ALTER LOGIN ' + QUOTENAME([p].[name]) + ' DISABLE;'
					ELSE ''
				END
				+ CASE
					WHEN [l2].[denylogin] = 1 AND [l2].[hasaccess] = 0 THEN ' DENY CONNECT SQL TO ' + QUOTENAME([p].[name]) + ';'
					WHEN [l2].[denylogin] = 0 AND [l2].[hasaccess] = 0 THEN ' REVOKE CONNECT SQL TO ' + QUOTENAME([p].[name]) + ';'
					ELSE ''
				END
			ELSE ' FROM WINDOWS WITH DEFAULT_DATABASE = ' + QUOTENAME([p].[default_database_name]) + ', DEFAULT_LANGUAGE = ' + QUOTENAME([p].[default_language_name]) + ';'
				+ CASE
					WHEN [p].[is_disabled] = 1 THEN ' ALTER LOGIN ' + QUOTENAME([p].[name]) + ' DISABLE;'
					ELSE ''
				END
				+ CASE
					WHEN [l2].[denylogin] = 1 AND [l2].[hasaccess] = 0 THEN ' DENY CONNECT SQL TO ' + QUOTENAME([p].[name]) + ';'
					WHEN [l2].[denylogin] = 0 AND [l2].[hasaccess] = 0 THEN ' REVOKE CONNECT SQL TO ' + QUOTENAME([p].[name]) + ';'
					ELSE ''
				END
		END [Statement]
		,[p].[default_database_name]
		,[p].[is_disabled]
		,[p].[create_date]
		,[p].[modify_date]
		,[l2].[denylogin]
		,[l2].[hasaccess]
		,CONVERT(NVARCHAR(MAX),[l2].[sid],1) AS [sid]
		,[p].[default_language_name] AS [language]
	FROM [sys].[server_principals] [p]
	LEFT JOIN [sys].[sql_logins] [l] ON [p].[sid] = [l].[sid]
	LEFT JOIN [sys].[syslogins] [l2] ON [p].[sid] = [l2].[sid]
	WHERE ([p].[type] IN ('U','G','S'))
	  AND ([p].[name] NOT LIKE N'##%')
	  AND ([p].[name] NOT LIKE N'NT %')
	  --AND ([p].[name] <> N'sa')
	  --AND ([p].[name] <> N'icesa')
) [a]
LEFT JOIN (
SELECT [x].[name] AS [LoginName], [Permissions] = STUFF((
	SELECT SPACE(2) + 'EXEC sp_addsrvrolemember @loginame = N''' + [l].[name] + ''', @rolename = N''' + [r].[name] + ''';'
	FROM [sys].[server_role_members] [m]
		JOIN [sys].[server_principals] [r] ON [r].[principal_id] = [m].[role_principal_id]
		JOIN [sys].[server_principals] [l] ON [l].[principal_id] = [m].[member_principal_id]
	WHERE ([l].[type] IN ('U','G','S'))
	  AND ([l].[name] NOT LIKE N'##%')
	  AND ([l].[name] NOT LIKE N'NT %')
	  --AND ([l].[name] <> N'sa')
	  --AND ([l].[name] <> N'icesa')
	  AND ([l].[sid] = [x].[sid])
	FOR XML PATH(''), TYPE).value('.[1]','VARCHAR(MAX)'),1,2,'')
FROM (
	SELECT 	
		[l].[sid]
		,[l].[name]
	FROM [sys].[server_role_members] [m]
		JOIN [sys].[server_principals] [r] ON [r].[principal_id] = [m].[role_principal_id]
		JOIN [sys].[server_principals] [l] ON [l].[principal_id] = [m].[member_principal_id]
	WHERE ([l].[type] IN ('U','G','S'))
	  AND ([l].[name] NOT LIKE N'##%')
	  AND ([l].[name] NOT LIKE N'NT %')
	  --AND ([l].[name] <> N'sa')
	  --AND ([l].[name] <> N'icesa')
) [x]
GROUP BY [x].[name], [x].[sid]
) [b] ON [a].[LoginName] = [b].[LoginName]
ORDER BY 2;
GO
