/****** Object:  StoredProcedure [dbo].[usp_SyncAG_Server_Logins_GetDatabasePerms]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_SyncAG_Server_Logins_GetDatabasePerms] (

	@db VARCHAR(50)
	,@sid NVARCHAR(128)
)
AS
SET NOCOUNT ON;
DECLARE @cmd NVARCHAR(MAX)

--DECLARE @db VARCHAR(50), @sid NVARCHAR(128)
--SET @db = 'production'
--SET @sid = '0x8381B7C3F2C3244D9FE1B24C1BCDB050'


SET @cmd = 'USE [' + @db + ']; ' +
'SELECT
	DB_NAME() AS [Database]
	,''' + @sid + ''' AS [sid]
	,CONVERT(NVARCHAR(128),[p].[sid],1) AS [RelatedSid]
	,[p].[name]
	,''ObjectPerms'' = [dp].[state_desc] + SPACE(1) + [dp].[permission_name] + '' ON '' + QUOTENAME([s].[name]) + ''.'' + QUOTENAME([o].[name]) + '' TO '' + QUOTENAME([p].[name]) + '';'' COLLATE DATABASE_DEFAULT
	,[ag] = (SELECT CASE WHEN [replica_id] IS NULL THEN 0 ELSE 1 END FROM [sys].[databases] WHERE ([name] = DB_NAME()))
FROM [sys].[database_permissions] [dp] (NOLOCK)
JOIN [sys].[database_principals] [p] (NOLOCK) ON [dp].[grantee_principal_id] = [p].[principal_id]
JOIN [sys].[objects] [o] (NOLOCK) ON [dp].[major_id] = [o].[object_id]
JOIN [sys].[schemas] [s] (NOLOCK) ON [o].[schema_id] = [s].[schema_id]
WHERE ([p].[principal_id] != 0)
	AND [p].[sid] IN (SELECT [sid] FROM [sys].[server_principals])
	AND CONVERT(NVARCHAR(128),[p].[sid],1) = ''' + @sid + '''
	OR [p].[name] IN (
	SELECT 
		USER_NAME([drm].[role_principal_id]) 
	FROM [sys].[database_principals] [dp]
	JOIN [sys].[database_role_members] [drm]
	ON [dp].[principal_id] = [drm].[member_principal_id] 
	WHERE [dp].[principal_id] NOT IN (0,1)
	  AND [dp].[sid] IN (SELECT [sid] FROM [sys].[server_principals])
	  AND CONVERT(NVARCHAR(128),[dp].[sid],1) = ''' + @sid + '''
	  AND [drm].[role_principal_id] = [p].[principal_id]
)
UNION
SELECT 
	DB_NAME() ''Database''
	,''' + @sid + ''' AS [sid]
	,CONVERT(NVARCHAR(128),[dp].[sid],1) AS [RelatedSid]
	,[dp].[name]
	,''EXEC sp_addrolemember N'''''' + USER_NAME([drm].[role_principal_id]) + '''''', N'''''' + [dp].[name] + '''''';'' AS [DBRole]
	,[ag] = (SELECT CASE WHEN [replica_id] IS NULL THEN 0 ELSE 1 END FROM [sys].[databases] WHERE ([name] = DB_NAME()))
FROM [sys].[database_principals] [dp]
LEFT JOIN [sys].[database_role_members] [drm]
ON [dp].[principal_id] = [drm].[member_principal_id] 
WHERE [dp].[principal_id] NOT IN (0,1)
  AND [dp].[sid] IN (SELECT [sid] FROM [sys].[server_principals])
  AND CONVERT(NVARCHAR(128),[dp].[sid],1) = ''' + @sid + '''
ORDER BY 3;'

EXEC(@cmd)
GO
