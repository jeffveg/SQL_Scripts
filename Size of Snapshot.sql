
CREATE FUNCTION fnBackupSize(@backupsize decimal(20,3))
RETURNS varchar(20)
AS
Begin
DECLARE @size varchar(20)
IF (@backupsize<1024)
Begin
Select @Size = cast(@backupsize as varchar(10)) +' Byte(s)'
End
IF (@backupsize>=1024 and @backupsize<=1048576)
Begin
Select @Size = cast(cast(@backupsize/1024 as decimal(20,3)) as varchar(10)) +' KByte(s)'
End
IF (@backupsize>=1048576 and @backupsize<=1073741824)
Begin
Select @Size = cast(cast(@backupsize/1048576 as decimal(20,3)) as varchar(10)) +' MByte(s)'
End
IF (@backupsize>=1073741824 and @backupsize<=1099511627776)
Begin
Select @Size =cast(cast(@backupsize/1073741824 as decimal(20,3)) as varchar(10)) +' GByte(s)'
End
IF (@backupsize>=1099511627776)
Begin
Select @Size =cast(cast(@backupsize/1099511627776 as decimal(20,3)) as varchar(10)) +' TByte(s)'
End

Return @size

End

go


SELECT  DB_NAME(sd.source_database_id) AS [SourceDatabase],
		sd.name AS [Snapshot],
		mf.name AS [Filename],
		master.dbo.fnBackupSize(size_on_disk_bytes) AS [size_on_disk],
		master.dbo.fnBackupSize((cast(mf2.size as bigint)/128)*1024*1024) AS [MaximumSize]
FROM sys.master_files mf
JOIN sys.databases sd
	ON mf.database_id = sd.database_id
JOIN sys.master_files mf2
	ON sd.source_database_id = mf2.database_id
	AND mf.file_id = mf2.file_id
CROSS APPLY sys.dm_io_virtual_file_stats(sd.database_id, mf.file_id)
WHERE mf.is_sparse = 1
AND mf2.is_sparse = 0
ORDER BY 1;

go

drop function dbo.fnBackupSize
