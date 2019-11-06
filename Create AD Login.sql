DECLARE
    @ULID INT
  , @DULID INT;

DECLARE
    @DomainGroup VARCHAR(50)
  , @FullUserName VARCHAR(50)
  , @Domain VARCHAR(20)
  , @FName VARCHAR(50)
  , @LName VARCHAR(50);


SELECT
    @Domain = 'ICEENTERPRISE'
  , @DomainGroup = 'ICEENTERPRISE\Sharepoint Admins'
  , @FullUserName = 'Jeffrey.Strong'
  , @FName = 'Jeffrey'
  , @LName = 'Strong';

PRINT 'Processing => ' + @FullUserName;

SELECT
    @ULID = ULID
FROM
    dbo.UserList
WHERE
    FullUserName = @DomainGroup;

SELECT
    @DULID = DULID
FROM
    dbo.DomainUserList
WHERE
    FullUserName = @FullUserName;

IF @DULID IS NULL
BEGIN
    PRINT 'Insert New Record into DomainUserList';
    INSERT INTO dbo.DomainUserList (
                                       FullUserName
                                     , Domain
                                     , FName
                                     , LName
                                     , DateAdded
                                     , DateDomainChecked
                                   )
    VALUES (
               @FullUserName, @Domain, @FName, @LName, GETDATE(), GETDATE()
           );

END;
ELSE
BEGIN

    PRINT 'Updating user info.';

    UPDATE
        dbo.DomainUserList
    SET
        Domain = ISNULL(@Domain, Domain)
      , FName = ISNULL(@FName, FName)
      , LName = ISNULL(@LName, LName)
      , DateDomainChecked = GETDATE()
    WHERE
        DULID = @DULID;

END;

IF NOT EXISTS (
                  SELECT
                      ID
                  FROM
                      dbo.UserListXDomainUserList
                  WHERE
                      DULID = @DULID
                      AND ULID = @ULID
              )
BEGIN
    PRINT 'Adding crossref';
    INSERT INTO dbo.UserListXDomainUserList (
                                                DULID
                                              , ULID
                                            )
    VALUES (
               @DULID, @ULID
           );

END;







SELECT
    *
FROM
    dbo.DomainUserList;
SELECT
    *
FROM
    dbo.UserListXDomainUserList;
