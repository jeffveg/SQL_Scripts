/* To fix broken log shipping.
   run a diff backup of affected DATABASE
	 update vars and restore diff with below script
	 restart copy and restore jobs */
	 
DECLARE @DBName sysname,@Path nvarchar(1000),@FileName nvarchar(1000),@SQL nvarchar(1000)

set @DBName = 'rf_xchng_hl7_WebPT'
set @FileName = 'DBPROD2PRI_rf_xchng_hl7_WebPT_DIFF_20190625_143221_1'
set @Path  = '\\dbadmin1.bmsalpha.com\Backup1\DBPROD2PRI\' + @DBName  + '\DIFF\'
--Set @Path = 'e:\Backups\'

if CHARINDEX(@DBName,@FileName)>1
begin
	set @FileName = left(@FileName, len(@FileName)-1)
	set @SQL = '
	RESTORE DATABASE [' + @DBName + '] FROM
	 DISK=''' + @Path + @FileName + '1.bak'',
	 DISK=''' + @Path + @FileName + '2.bak'',
	 DISK=''' + @Path + @FileName + '3.bak'',
	 DISK=''' + @Path + @FileName + '4.bak'',
	 DISK=''' + @Path + @FileName + '5.bak''
	   WITH NORECOVERY, STATS = 1'

   print @SQL
   exec sp_executesql @SQL
 end
