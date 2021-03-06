/****** Object:  StoredProcedure [dbo].[GetLogins]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetLogins] (@login_name sysname = NULL) 
AS
DECLARE @name sysname
DECLARE @type varchar (1)
DECLARE @hasaccess int
DECLARE @denylogin int
DECLARE @is_disabled int
DECLARE @PWD_varbinary  varbinary (256)
DECLARE @PWD_string  varchar (514)
DECLARE @SID_varbinary varbinary (85)
DECLARE @SID_string varchar (514)
DECLARE @tmpstmt  varchar (4000)
DECLARE @is_policy_checked varchar (3)
DECLARE @is_expiration_checked varchar (3)
DECLARE @createdate DATETIME
DECLARE @modifieddate DATETIME


DECLARE @defaultdb sysname

DECLARE @tmpLoginsTbl TABLE (
	id int IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED
	,LoginName VARCHAR(255)
	,[Statement] VARCHAR(4000)
	,defaultdb VARCHAR(255)
	,isDisabled BIT
	,CreateDate DATETIME
	,ModifyDate DATETIME) 

IF (@login_name IS NULL)
  DECLARE login_curs CURSOR FOR

SELECT 
	[p].[sid]
	,[p].[name]
	,[p].[type]
	,[p].[is_disabled]
	,[p].[default_database_name]
	,[l].[hasaccess]
	,[l].[denylogin]
	,[p].[create_date]
	,[p].[modify_date]
FROM [sys].[server_principals] [p] 
LEFT JOIN [sys].[syslogins] [l] ON [l].[name] = [p].[name] 
WHERE [p].[type] IN ( 'S', 'G', 'U' ) 
  AND [p].[name] <> 'sa' 
  AND [p].[name] NOT LIKE N'##MS%' 
  AND [p].[name] NOT LIKE N'NT%' 
  AND [p].[sid] != 0x01;

ELSE
  DECLARE login_curs CURSOR FOR
	SELECT 
		[p].[sid]
		,[p].[name]
		,[p].[type]
		,[p].[is_disabled]
		,[p].[default_database_name]
		,[l].[hasaccess]
		,[l].[denylogin]
		,[p].[create_date]
		,[p].[modify_date]
	FROM [sys].[server_principals] [p] 
	LEFT JOIN [sys].[syslogins] [l] ON [l].[name] = [p].[name] 
	WHERE [p].[type] IN ( 'S', 'G', 'U' ) 
	  AND [p].[name] = @login_name 
	  AND [p].[name] NOT LIKE N'##MS%' 
	  AND [p].[name] NOT LIKE N'NT%' 
	  AND [p].[sid] != 0x01;
OPEN login_curs

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin, @createdate, @modifieddate
IF (@@fetch_status = -1)
BEGIN
  SELECT 'No login(s) found.'
  CLOSE login_curs
  DEALLOCATE login_curs
  RETURN -1
END
WHILE (@@fetch_status <> -1)
BEGIN
  IF (@@fetch_status <> -2)
  BEGIN

    IF (@type IN ( 'G', 'U'))
    BEGIN -- NT authenticated account/group

      SET @tmpstmt = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'
    END
    ELSE BEGIN -- SQL Server authentication
        -- obtain password and sid
            SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )
        EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT
        EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT
 
        -- obtain password policy state
        SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
        SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
 
            SET @tmpstmt = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'

        IF ( @is_policy_checked IS NOT NULL )
        BEGIN
          SET @tmpstmt = @tmpstmt + ', CHECK_POLICY = ' + @is_policy_checked
        END
        IF ( @is_expiration_checked IS NOT NULL )
        BEGIN
          SET @tmpstmt = @tmpstmt + ', CHECK_EXPIRATION = ' + @is_expiration_checked
        END
    END
    IF (@denylogin = 1)
    BEGIN -- login is denied access
      SET @tmpstmt = @tmpstmt + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )
    END
    ELSE IF (@hasaccess = 0)
    BEGIN -- login exists but does not have access
      SET @tmpstmt = @tmpstmt + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )
    END
    IF (@is_disabled = 1)
    BEGIN -- login is disabled
      SET @tmpstmt = @tmpstmt + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'
    END

	INSERT INTO @tmpLoginsTbl (LoginName, [Statement], defaultdb, isDisabled, CreateDate, ModifyDate) VALUES (@name, 'IF EXISTS (SELECT [name] FROM [sys].[server_principals] WHERE ([name] = N''' + @name + ''')) BEGIN DROP LOGIN [' + @name + ']; END ' + @tmpstmt + ';', @defaultdb, @is_disabled, @createdate, @modifieddate)

  END

  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin, @createdate, @modifieddate
   END
CLOSE login_curs
DEALLOCATE login_curs

SELECT id, LoginName, [Statement], defaultdb, isDisabled, CreateDate, ModifyDate FROM @tmpLoginsTbl ORDER BY id
RETURN 0

GO
