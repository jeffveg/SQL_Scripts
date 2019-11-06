DECLARE @l_spid VARCHAR(4)
   ,@l_hostname VARCHAR(20);

DECLARE kill_cursor SCROLL CURSOR
FOR
    SELECT  CONVERT(VARCHAR(4), spid)
           ,hostname
    FROM    master..sysprocesses WITH ( NOLOCK )
    WHERE   loginame = 'sa'
            AND hostname <> '';

OPEN kill_cursor;
SELECT  @@cursor_rows;

FETCH NEXT FROM kill_cursor INTO @l_spid, @l_hostname;
WHILE ( @@fetch_status = 0 )
    BEGIN
        SELECT  @l_hostname Killed;
        EXEC ( 'kill ' + @l_spid);
        FETCH NEXT FROM kill_cursor INTO @l_spid, @l_hostname;
    END;
CLOSE kill_cursor;
DEALLOCATE kill_cursor;
