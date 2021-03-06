/****** Object:  StoredProcedure [dbo].[usp_SyncAG_GetLoginDatabaseRolesByDatabase]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_SyncAG_GetLoginDatabaseRolesByDatabase]
AS
SET NOCOUNT ON;
IF OBJECT_ID('[dbo].[SyncAG_Logins_DBRoles]') IS NOT NULL
	BEGIN
		DROP TABLE [dbo].[SyncAG_Logins_DBRoles]
	END

CREATE TABLE [dbo].[SyncAG_Logins_DBRoles] (
	id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED
	,[sid] NVARCHAR(128) NOT NULL
	,[User] NVARCHAR(75) NOT NULL
	,[Database] VARCHAR(50) NOT NULL
	,[Perms] NVARCHAR(MAX) NULL
	,[AG] BIT NULL
);

DECLARE @cnt INT, @rcnt INT, @db VARCHAR(50), @cmd VARCHAR(MAX)
DECLARE @tbldbs TABLE (
	id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED
	,db VARCHAR(50)
	,ag BIT
)
INSERT INTO @tbldbs ([db], [ag])
SELECT
	[name]
	,CASE
		WHEN [group_database_id] IS NULL THEN 0
		ELSE 1
	END AS [ag]
FROM [sys].[databases]
WHERE [database_id] <> 2;
SET @rcnt = @@ROWCOUNT;
SET @cnt = 1;

WHILE (@cnt <= @rcnt)
	BEGIN
		SELECT @db = [db] FROM @tbldbs WHERE (id = @cnt)
		SET @cmd = 'USE [' + @db +']; ' 
		SET @cmd = @cmd + 'INSERT INTO [master].[dbo].[SyncAG_Logins_DBRoles] ([sid], [User], [Database],[Perms])'
		SET @cmd = @cmd + 
			'SELECT
				CONVERT(NVARCHAR(MAX),[d].[sid],1) AS [sid]
				,[d].[User]
				,[d].[Database]
				,[Perms] = ''USE ['' + [d].[Database] + '']; '' + STUFF(( SELECT SPACE(2) + ''EXEC sp_addsrvrolemember @loginame = N'''''' + [m].[name] + '''''', @rolename = N'''''' + [p].[name] + '''''';''
			FROM [sys].[database_role_members] [rm] (NOLOCK)
			JOIN [sys].[database_principals] [p] (NOLOCK) ON [rm].[role_principal_id] = [p].[principal_id]
			JOIN [sys].[database_principals] [m] (NOLOCK) ON [rm].[member_principal_id] = [m].[principal_id]
			WHERE [m].[sid] IN (
				SELECT 
					[l].[sid]
				FROM [sys].[server_principals] [l] 
				WHERE ([l].[type] IN (''U'',''G'',''S''))
					AND ([l].[name] NOT LIKE N''##%'')
					AND ([l].[name] NOT LIKE N''NT %'')
					--AND ([l].[name] <> N''sa'')
					AND ([l].[name] <> N''icesa'')
					AND [l].[sid] = [d].[sid]
			) FOR XML PATH(''''), TYPE).value(''.[1]'',''VARCHAR(MAX)''),1,2,'''')
			FROM (
				SELECT
					 DB_NAME() AS [Database]
					,[m].[name] AS [User]
					,[p].[name] AS [Role]
					,[m].[sid] AS [sid]
				FROM [sys].[database_role_members] [rm] (NOLOCK)
				JOIN [sys].[database_principals] [p] (NOLOCK) ON [rm].[role_principal_id] = [p].[principal_id]
				RIGHT JOIN [sys].[database_principals] [m] (NOLOCK) ON [rm].[member_principal_id] = [m].[principal_id]
				WHERE [m].[sid] IN (
					SELECT 
						[l].[sid]
					FROM [sys].[server_principals] [l] 
					WHERE ([l].[type] IN (''U'',''G'',''S''))
						AND ([l].[name] NOT LIKE N''##%'')
						AND ([l].[name] NOT LIKE N''NT %'')
						--AND ([l].[name] <> N''sa'')
						AND ([l].[name] <> N''icesa'')
				)
			) AS [d]
			GROUP BY [d].[Database], [d].[User], [d].[sid];'
		EXEC(@cmd)
		SET @cnt = @cnt + 1;
	END

	UPDATE [r]
		SET [r].[AG] = CASE WHEN [d].[group_database_id] IS NULL THEN 0 ELSE 1 END
	FROM [master].[dbo].[SyncAG_Logins_DBRoles] [r]
	JOIN [sys].[databases] [d] ON [r].[Database] = [d].[name];

	--SELECT 
	--	[a].[sid]
	--	,[a].[User]
	--	,[perms] = STUFF(( SELECT SPACE(2) + [b].[perms] 
	--	FROM [dbo].[SyncAG_Logins_DBRoles] [b]
	--	WHERE [b].[sid] = [a].[sid]
	--	FOR XML PATH(''), TYPE).value('.[1]','VARCHAR(MAX)'),1,2,'')
	--FROM (
	--	SELECT
	--		[sid]
	--		,[User]
	--		,[Database]
	--	FROM [dbo].[SyncAG_Logins_DBRoles] 
	--) AS [a]
	--WHERE [a].[User] <> 'dbo'
	--GROUP BY [a].[sid], [a].[User];
GO
