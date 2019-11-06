


/*********************************************************************

1) This section used to display Server Names Before making changes

*********************************************************************/

DECLARE @old_name varchar(128), 
@win_nt_server_name varchar(128), 
@server_name varchar(128)

SELECT @old_name = CONVERT(VARCHAR(128), @@SERVERNAME), 
@win_nt_server_name = CONVERT(VARCHAR(128), Serverproperty('Servername')), 
@server_name = (SELECT TOP (1) name from master.sys.servers)

PRINT 'Local SQL Server name:' + @old_name
PRINT 'WindowsNT Server name:' + @win_nt_server_name
PRINT 'Server name:' + @server_name

/*********************************************************************
2) The business end
*********************************************************************/

exec sp_dropserver @server_name
GO

exec sp_addserver 'YOUR_NEW_SQL_SERVER_NAME', local
GO

/*********************************************************************
3) This section used to display Server Names AFTER making changes
*********************************************************************/
PRINT '' -- new line
--Need to redeclare all variables after is dropped and renamed

DECLARE @old_name varchar(128), 
@win_nt_server_name varchar(128), 
@server_name varchar(128)

SELECT @old_name = CONVERT(VARCHAR(128), @@SERVERNAME), 
@win_nt_server_name = CONVERT(VARCHAR(128), Serverproperty('Servername')), 
@server_name = (SELECT TOP (1) name from master.sys.servers)

PRINT 'Local SQL Server name:' + @old_name
PRINT 'WindowsNT Server name:' + @win_nt_server_name
PRINT 'Server name:' + @server_name