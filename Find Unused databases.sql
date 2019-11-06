/****************************************************	
* Cool script found http://dba.stackexchange.com	*
* that will show a list of DB's that have not been	*
* Accessed since the last reboot			*
* Note: The system view sys.dm_db_index_usage_stats	*
* 	gets cleared each reboot			*
*****************************************************/
use master
go 


SELECT  [name]
FROM    sys.databases
WHERE   database_id > 4
        AND [name] NOT IN (
        SELECT  DB_NAME(database_id)
        FROM    sys.dm_db_index_usage_stats
        WHERE   COALESCE(last_user_seek, last_user_scan, last_user_lookup,
                         '1/1/1970') > (SELECT  login_time
                                        FROM    sysprocesses
                                        WHERE   spid = 1))