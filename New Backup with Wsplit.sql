Alter PROC sp_BackupDataDomainFull
    (
        @BackUpPath NVARCHAR(1000)
      , @NumberOfDaysToKeep INT
    )
AS
    --SET @BackUpPath = '\\us-att-dd01\sql\AMEX01\';
    DECLARE @DTStamp VARCHAR(28);
    DECLARE @DTDelete VARCHAR(28);
    DECLARE @Statment NVARCHAR(4000);
    DECLARE @DBName NVARCHAR(255);
    DECLARE @DBSize INT;
    DECLARE @NumFiles INT;

    IF @NumberOfDaysToKeep > 0
        SET @NumberOfDaysToKeep = @NumberOfDaysToKeep * -1;

    PRINT @NumberOfDaysToKeep;
    SET @DTDelete = CONVERT(VARCHAR(19), DATEADD(DAY, @NumberOfDaysToKeep, GETDATE()), 121);
    SET @DTDelete = REPLACE(@DTDelete, ' ', 'T');
    SET @DTStamp = CONVERT(VARCHAR(28), GETDATE(), 121);
    SET @DTStamp = REPLACE(@DTStamp, '-', '_');
    SET @DTStamp = REPLACE(@DTStamp, ' ', '_');
    SET @DTStamp = REPLACE(@DTStamp, ':', '');
    SET @DTStamp = REPLACE(@DTStamp, '.', '_');

    PRINT @DTStamp;

    DECLARE cBackup CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT
            name
        FROM
            master.sys.databases
        WHERE
            name NOT IN ( 'Tempdb' );

    OPEN cBackup;

    FETCH NEXT FROM cBackup
    INTO
        @DBName;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        SET @Statment = 'SELECT @DBSize = SUM(size)/128/1024 FROM [' + @DBName + '].sys.sysfiles WHERE GROUPid > 0 ';
        EXEC sys.sp_executesql
            @Statment
          , @params = N'@DBSize INT OUTPUT'
          , @DBSize = @DBSize OUTPUT;
       -- PRINT @DBSize;

        SET @Statment = 'EXECUTE master.dbo.xp_create_subdir ''' + @BackUpPath + @DBName + '''';
        EXEC sys.sp_executesql
            @Statment;

        SET @Statment = 'EXECUTE master.dbo.xp_delete_file 0,N''' + @BackUpPath + @DBName + ''',N''bak'',N'''
                        + @DTDelete + ''',1';
        EXEC sys.sp_executesql
            @Statment;

        SET @Statment = 'BACKUP DATABASE [' + @DBName + '] TO  DISK = ''' + @BackUpPath + @DBName + '\' + @DBName
                        + '_backup_' + @DTStamp + '.bak'' ' + CHAR(13) + CHAR(10);
        IF @DBSize > 10
        BEGIN
            SET @Statment = 'BACKUP DATABASE [' + @DBName + '] TO  DISK = ''' + @BackUpPath + @DBName + '\' + @DBName
                            + '_backup_' + @DTStamp + '_1.bak'' ' + CHAR(13) + CHAR(10);
            SET @Statment += '  , DISK = ''' + @BackUpPath + @DBName + '\' + @DBName + '_backup_' + @DTStamp
                             + '_2.bak'' ' + CHAR(13) + CHAR(10);
        END;
        IF @DBSize > 25
        BEGIN
            SET @Statment += '  , DISK = ''' + @BackUpPath + @DBName + '\' + @DBName + '_backup_' + @DTStamp
                             + '_3.bak'' ' + CHAR(13) + CHAR(10);
        END;
        IF @DBSize > 50
        BEGIN
            SET @Statment += '  , DISK = ''' + @BackUpPath + @DBName + '\' + @DBName + '_backup_' + @DTStamp
                             + '_4.bak'' ' + CHAR(13) + CHAR(10);
        END;
        IF @DBSize > 100
        BEGIN
            SET @Statment += '  , DISK = ''' + @BackUpPath + @DBName + '\' + @DBName + '_backup_' + @DTStamp
                             + '_5.bak'' ' + CHAR(13) + CHAR(10);
        END;
        IF @DBSize > 200
        BEGIN
            SET @Statment += '  , DISK = ''' + @BackUpPath + @DBName + '\' + @DBName + '_backup_' + @DTStamp
                             + '_6.bak'' ' + CHAR(13) + CHAR(10);
        END;
        IF @DBSize > 400
        BEGIN
            SET @Statment += '  , DISK = ''' + @BackUpPath + @DBName + '\' + @DBName + '_backup_' + @DTStamp
                             + '_7.bak'' ' + CHAR(13) + CHAR(10);
        END;
        IF @DBSize > 800
        BEGIN
            SET @Statment += '  , DISK = ''' + @BackUpPath + @DBName + '\' + @DBName + '_backup_' + @DTStamp
                             + '_8.bak'' ' + CHAR(13) + CHAR(10);
        END;

        SET @Statment += 'WITH NOFORMAT, NOINIT, NAME = ''' + @DBName + 'backup_' + @DTStamp
                         + ''', SKIP, REWIND, NOUNLOAD, copy_only,NO_COMPRESSION, STATS = 10';

        PRINT @Statment;
        EXEC sys.sp_executesql
            @Statment;

        FETCH NEXT FROM cBackup
        INTO
            @DBName;

    END;

    CLOSE cBackup;
    DEALLOCATE cBackup;
