USE DBM
GO

SET NOCOUNT ON

BEGIN TRY
	DROP PROCEDURE #sp_hexadecimal
END TRY

BEGIN CATCH
END CATCH;
GO

CREATE PROCEDURE #sp_hexadecimal @binvalue VARBINARY(256)
	, @hexvalue VARCHAR(514) OUTPUT
AS
DECLARE @charvalue VARCHAR(514)
DECLARE @i INT
DECLARE @length INT
DECLARE @hexstring CHAR(16)

SELECT @charvalue = '0x'

SELECT @i = 1

SELECT @length = DATALENGTH(@binvalue)

SELECT @hexstring = '0123456789ABCDEF'

WHILE (@i <= @length)
BEGIN
	DECLARE @tempint INT
	DECLARE @firstint INT
	DECLARE @secondint INT

	SELECT @tempint = CONVERT(INT, SUBSTRING(@binvalue, @i, 1))

	SELECT @firstint = FLOOR(@tempint / 16)

	SELECT @secondint = @tempint - (@firstint * 16)

	SELECT @charvalue = @charvalue + SUBSTRING(@hexstring, @firstint + 1, 1) + SUBSTRING(@hexstring, @secondint + 1, 1)

	SELECT @i = @i + 1
END

SELECT @hexvalue = @charvalue
GO

BEGIN TRY
	DROP PROCEDURE #sp_help_revlogin
END TRY

BEGIN CATCH
END CATCH;
GO

CREATE PROCEDURE #sp_help_revlogin @login_name SYSNAME = NULL
AS
DECLARE @name SYSNAME
DECLARE @type VARCHAR(1)
DECLARE @hasaccess INT
DECLARE @denylogin INT
DECLARE @is_disabled INT
DECLARE @PWD_varbinary VARBINARY(256)
DECLARE @PWD_string VARCHAR(514)
DECLARE @SID_varbinary VARBINARY(85)
DECLARE @SID_string VARCHAR(514)
DECLARE @tmpstr VARCHAR(1024)
DECLARE @is_policy_checked VARCHAR(3)
DECLARE @is_expiration_checked VARCHAR(3)

IF (@login_name IS NULL)
	DECLARE login_curs CURSOR
	FOR
	SELECT p.sid
		, p.NAME
		, p.type
		, p.is_disabled
		, l.hasaccess
		, l.denylogin
	FROM sys.server_principals p
	LEFT JOIN sys.syslogins l
		ON (l.NAME = p.NAME)
	WHERE p.type IN (
			'S'
			, 'G'
			, 'U'
			)
		AND p.NAME <> 'sa' ELSE

DECLARE login_curs CURSOR
FOR
SELECT p.sid
	, p.NAME
	, p.type
	, p.is_disabled
	, l.hasaccess
	, l.denylogin
FROM sys.server_principals p
LEFT JOIN sys.syslogins l
	ON (l.NAME = p.NAME)
WHERE p.type IN (
		'S'
		, 'G'
		, 'U'
		)
	AND p.NAME = @login_name

OPEN login_curs

FETCH NEXT
FROM login_curs
INTO @SID_varbinary
	, @name
	, @type
	, @is_disabled
	, @hasaccess
	, @denylogin

IF (@@fetch_status = - 1)
BEGIN
	PRINT 'No login(s) found.'

	CLOSE login_curs

	DEALLOCATE login_curs

	RETURN - 1
END

SET @tmpstr = '/* sp_help_revlogin script '

PRINT @tmpstr

SET @tmpstr = '** Generated ' + CONVERT(VARCHAR, GETDATE()) + ' on ' + @@SERVERNAME + ' */'

PRINT @tmpstr
PRINT ''

WHILE (@@fetch_status <> - 1)
BEGIN
	IF (@@fetch_status <> - 2)
	BEGIN
		PRINT ''

		SET @tmpstr = '-- Login: ' + @name

		PRINT @tmpstr

		IF (
				@type IN (
					'G'
					, 'U'
					)
				)
		BEGIN -- NT authenticated account/group
			SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME(@name) + ' FROM WINDOWS'
		END
		ELSE
		BEGIN -- SQL Server authentication
			-- obtain password and sid
			SET @PWD_varbinary = CAST(LOGINPROPERTY(@name, 'PasswordHash') AS VARBINARY(256))

			EXEC #sp_hexadecimal @PWD_varbinary
				, @PWD_string OUTPUT

			EXEC #sp_hexadecimal @SID_varbinary
				, @SID_string OUTPUT

			-- obtain password policy state
			SELECT @is_policy_checked = CASE is_policy_checked
					WHEN 1
						THEN 'ON'
					WHEN 0
						THEN 'OFF'
					ELSE NULL
					END
			FROM sys.sql_logins
			WHERE NAME = @name

			SELECT @is_expiration_checked = CASE is_expiration_checked
					WHEN 1
						THEN 'ON'
					WHEN 0
						THEN 'OFF'
					ELSE NULL
					END
			FROM sys.sql_logins
			WHERE NAME = @name

			SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME(@name) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string

			IF (@is_policy_checked IS NOT NULL)
			BEGIN
				SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked
			END

			IF (@is_expiration_checked IS NOT NULL)
			BEGIN
				SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked
			END
		END

		IF (@denylogin = 1)
		BEGIN -- login is denied access
			SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME(@name)
		END
		ELSE IF (@hasaccess = 0)
		BEGIN -- login has exists but does not have access
			SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME(@name)
		END

		IF (@is_disabled = 1)
		BEGIN -- login is disabled
			SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME(@name) + ' DISABLE'
		END

		PRINT @tmpstr
	END

	FETCH NEXT
	FROM login_curs
	INTO @SID_varbinary
		, @name
		, @type
		, @is_disabled
		, @hasaccess
		, @denylogin
END

CLOSE login_curs

DEALLOCATE login_curs

RETURN 0
GO

EXEC #sp_help_revlogin

PRINT 'GO'
PRINT ''
PRINT '-- Add Server Roles'

DECLARE @SQL VARCHAR(400)

CREATE TABLE #Logins (
	NAME SYSNAME NULL
	, Type_Desc VARCHAR(200) NULL
	, ROLE SYSNAME NULL
	, SID VARBINARY(8000) NULL
	)

INSERT INTO #Logins
SELECT PRN.NAME
	, Prn.Type_Desc
	, srvrole.NAME AS [role]
	, prn.SID
FROM master.sys.server_role_members membership
INNER JOIN (
	SELECT *
	FROM master.sys.server_principals
	WHERE type_desc = 'SERVER_ROLE'
	) srvrole
	ON srvrole.Principal_id = membership.Role_principal_id
RIGHT JOIN master.sys.server_principals PRN
	ON PRN.Principal_id = membership.member_principal_id
WHERE Prn.Type_Desc NOT IN ('SERVER_ROLE')
	AND PRN.is_disabled = 0

-- =============================================
-- Declare and using a READ_ONLY cursor
-- =============================================
DECLARE cPrint CURSOR READ_ONLY
FOR
SELECT 'EXEC sp_addsrvrolemember  [' + NAME + '],[' + ROLE + ']'
FROM #Logins
WHERE ROLE IS NOT NULL
	AND Type_Desc IN (
		'WINDOWS_GROUP'
		, 'WINDOWS_LOGIN'
		, 'SQL_LOGIN'
		)
	AND sid <> 0x01

OPEN cPrint

FETCH NEXT
FROM cPrint
INTO @SQL

WHILE (@@fetch_status <> - 1)
BEGIN
	IF (@@fetch_status <> - 2)
	BEGIN
		PRINT @SQL
		PRINT 'Go'
	END

	FETCH NEXT
	FROM cPrint
	INTO @SQL
END

CLOSE cPrint

DEALLOCATE cPrint
GO

DROP TABLE #Logins

PRINT 'GO'
PRINT ''
PRINT '-- Set DEFAULT_DATABASE and DEFAULT_LANGUAGE'

DECLARE @Name SYSNAME
	, @DDB SYSNAME
	, @DLG SYSNAME
	, @Message VARCHAR(4000)

DECLARE cUserDBLang CURSOR READ_ONLY
FOR
SELECT NAME
	, default_database_name
	, default_language_name
FROM master.sys.server_principals membership
WHERE Type_Desc NOT IN (
		'SERVER_ROLE'
		, 'CERTIFICATE_MAPPED_LOGIN'
		)
	AND is_disabled = 0

OPEN cUserDBLang

FETCH NEXT
FROM cUserDBLang
INTO @Name
	, @DDB
	, @DLG

WHILE (@@fetch_status <> - 1)
BEGIN
	IF (@@fetch_status <> - 2)
	BEGIN
		SELECT @Message = 'ALTER LOGIN [' + @name + '] WITH DEFAULT_DATABASE = [' + @DDB + '], DEFAULT_LANGUAGE = ' + @DLG

		PRINT @Message
		PRINT 'GO'
	END

	FETCH NEXT
	FROM cUserDBLang
	INTO @name
		, @DDB
		, @DLG
END

CLOSE cUserDBLang

DEALLOCATE cUserDBLang
GO


