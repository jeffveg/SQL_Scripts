/****** Object:  StoredProcedure [dbo].[sp_DBA_BackupToAzureFull]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_DBA_BackupToAzureFull]
    (
        @storage VARCHAR(30)
      , @container VARCHAR(100)
      , @credential VARCHAR(65)
      , @PrintOnly BIT = 0
    )
AS
    DECLARE @BackUpPath NVARCHAR(1000);
    --SET @BackUpPath = 'L:\Backups\'
    SET @BackUpPath = N'https://' + @storage + N'.blob.core.windows.net/';

    DECLARE @DTStamp VARCHAR(28);
    DECLARE @Statment NVARCHAR(4000);
    DECLARE @DBName NVARCHAR(255);

    SET @DTStamp = CONVERT(VARCHAR(28), GETDATE(), 121);
    SET @DTStamp = REPLACE(@DTStamp, '-', '_');
    SET @DTStamp = REPLACE(@DTStamp, ' ', '_');
    SET @DTStamp = REPLACE(@DTStamp, ':', '');
    SET @DTStamp = REPLACE(@DTStamp, '.', '_');

    --PRINT @DTStamp

    DECLARE cBackup CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT
            name
        FROM
            master.sys.databases
        WHERE
            name NOT IN ( 'tempdb' );

    OPEN cBackup;

    FETCH NEXT FROM cBackup
    INTO
        @DBName;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        SET @Statment = N'BACKUP database [' + @DBName + N'] TO URL = ''' + @BackUpPath + @container + N'/' + @DBName
                        + N'_backup_' + @DTStamp + N'.bak'' WITH CREDENTIAL =''' + @credential
                        + N''', COMPRESSION, STATS = 5;';

        IF @PrintOnly = 1
        BEGIN
            PRINT @Statment;
        END;
        ELSE
        BEGIN
            EXEC sys.sp_executesql
                @Statment;
        END;



        FETCH NEXT FROM cBackup
        INTO
            @DBName;

    END;

    CLOSE cBackup;
    DEALLOCATE cBackup;
GO
