    
    DECLARE @spid INT
      , @cnt INT
      , @sql VARCHAR(255)
      , @DBName NVARCHAR(32)
      , @Username NVARCHAR(32)

    SET @Username = 'NTBANK\req81825'
    SET @DBName = 'dbadb'

    SELECT  @spid = MIN(blocked)
          , @cnt = COUNT(*)
    FROM    sysprocesses
    WHERE   dbid = (SELECT  dbid
                    FROM    sys.sysdatabases
                    WHERE   name = @DBName)
            AND loginame = @Username
            AND blocked <> 0
            AND spid != @@SPID
            AND spid > 50

 
 
    PRINT 'Starting to KILL ' + RTRIM(@cnt) + ' processes.' 
     
    WHILE @spid IS NOT NULL 
        BEGIN 
            PRINT 'About to KILL ' + RTRIM(@spid)  
            SET @sql = 'KILL ' + RTRIM(@spid) 
            EXEC(@sql)  
            SELECT  @spid = MIN(blocked)
                  , @cnt = COUNT(*)
            FROM    sysprocesses
            WHERE   dbid = (SELECT  dbid
                            FROM    sys.sysdatabases
                            WHERE   name = @DBName)
                    AND loginame = @Username
                    AND blocked <> 0
                    AND spid != @@SPID
                    AND spid > 50
            PRINT RTRIM(@cnt) + ' processes remain.' 
        END 
