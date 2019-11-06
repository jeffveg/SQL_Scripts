DECLARE @profile_name SYSNAME
	, @account_name SYSNAME
	, @SMTP_servername SYSNAME
	, @email_address NVARCHAR(128)
	, @display_name NVARCHAR(128)
	, @ErrMessage VARCHAR(100);

-- Profile name. Replace with the name for your profile
SET @profile_name = @@servername
-- Account information. Replace with the information for your account.
SET @account_name = @@servername + ' DB Mail';
SET @SMTP_servername = 'smtp.iceenterprise.com';
SET @email_address = 'databaseadmins@iceenterprise.com';
SET @display_name = @account_name ;

-- Verify the specified account and profile do not already exist.
IF EXISTS (
		SELECT *
		FROM msdb.dbo.sysmail_profile
		WHERE NAME = @profile_name
		)
BEGIN
	SET @ErrMessage = 'The specified Database Mail profile (' + @profile_name + ') already exists.';

	RAISERROR (
			@ErrMessage
			, 16
			, 1
			);

	GOTO done;
END;

IF EXISTS (
		SELECT *
		FROM msdb.dbo.sysmail_account
		WHERE NAME = @account_name
		)
BEGIN
	SET @ErrMessage = 'The specified Database Mail account (' + @account_name + ') already exists.';

	RAISERROR (
			@ErrMessage
			, 16
			, 1
			);

	GOTO done;
END;

-- Start a transaction before adding the account and the profile
BEGIN TRANSACTION;

DECLARE @rv INT;

-- Add the account
EXECUTE @rv = msdb.dbo.sysmail_add_account_sp @account_name = @account_name
	, @email_address = @email_address
	, @display_name = @display_name
	, @mailserver_name = @SMTP_servername
	, @Description = 'Default DB Mail Account for this server';

IF @rv <> 0
BEGIN
	SET @ErrMessage = 'Failed to create the specified Database Mail account (' + @account_name + ').';

	RAISERROR (
			@ErrMessage
			, 16
			, 1
			);

	ROLLBACK TRANSACTION;

	GOTO done;
END

-- Add the profile
EXECUTE @rv = msdb.dbo.sysmail_add_profile_sp @profile_name = @profile_name;

IF @rv <> 0
BEGIN
	SET @ErrMessage = 'Failed to create the specified Database Mail profile (' + @profile_name + ') already exists.';

	RAISERROR (
			@ErrMessage
			, 16
			, 1
			);

	ROLLBACK TRANSACTION;

	GOTO done;
END;

-- Associate the account with the profile.
EXECUTE @rv = msdb.dbo.sysmail_add_profileaccount_sp @profile_name = @profile_name
	, @account_name = @account_name
	, @sequence_number = 1;

IF @rv <> 0
BEGIN
	RAISERROR (
			'Failed to associate the speficied profile with the specified account.'
			, 16
			, 1
			);

	ROLLBACK TRANSACTION;

	GOTO done;
END;

EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = @profile_name,
    @principal_name = 'public',
    @is_default = 1 ;


	IF @rv <> 0
BEGIN
	RAISERROR (
			'Failed to create the public profile.'
			, 16
			, 1
			);

	ROLLBACK TRANSACTION;

	GOTO done;
END;


COMMIT TRANSACTION;

done:
GO
