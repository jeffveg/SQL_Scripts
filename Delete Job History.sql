DECLARE @DTDelete VARCHAR(28)

SET @DTDelete = CONVERT(VARCHAR(19),DATEADD(WEEK,-9,GETDATE()),121)
SET @DTDelete = REPLACE(@DTDelete,' ','T')

exec msdb.dbo.sp_delete_backuphistory @DTDelete 

EXEC msdb.dbo.sp_purge_jobhistory  @oldest_date=@DTDelete 

EXECUTE msdb..sp_maintplan_delete_log null,null,@DTDelete 
