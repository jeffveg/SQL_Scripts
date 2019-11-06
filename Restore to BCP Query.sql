DECLARE @File VARCHAR(1000)
DECLARE @Pass VARCHAR(1000)
DECLARE @SQL NVARCHAR(4000)
DECLARE @Database VARCHAR(32)
-- Drop table #Table
-- set these variables 
SET @File = 'I:\LogShip\FULL_(local)_Staging_20100605_001144.sqb'
SET @Database = 'Staging'

-- Change this if needed
SET @Pass = 'R3dG@teH@sC00lSof7war3'


-- below is the magic 
SET NOCOUNT ON
PRINT 'Reading File => '+ @FILE  + ' at ' + convert(VARCHAR(20), GETDATE(), 14)
SET @SQL = 'exec master..sqlbackup N''-SQL "RESTORE FILELISTONLY FROM DISK = ''''' + @File + ''''' with PASSWORD = ''''' + @Pass + '''''"'''
-- PRINT @SQL 

CREATE TABLE #Table (
	LogicalName VARCHAR(128),
	PhysicalName VARCHAR(128),
	FileType CHAR(1),
	FileGroupName VARCHAR(128),
	FileSize BIGINT,
	FileMaxSize BIGINT
	)

INSERT INTO #Table (
	LogicalName,
	PhysicalName,
	FileType,
	FileGroupName,
	FileSize,
	FileMaxSize
) 
EXEC sp_executesql @SQL
PRINT 'Finished File => '+ @FILE  + ' at ' + convert(VARCHAR(20), GETDATE(), 14)
PRINT ''
--SELECT * FROM #Table

-- Restore the database incase there was a stuck backup
PRINT 'Restoring DB => ' + @Database + ' at ' + convert(VARCHAR(20), GETDATE(), 14)
SET @SQL = 'RESTORE DATABASE [' + @Database + '] WITH RECOVERY'
EXEC sp_executesql @SQL
PRINT 'Restored DB => ' + @Database + ' at ' + convert(VARCHAR(20), GETDATE(), 14)
PRINT ''

-- Drop the database
PRINT 'Dropping DB => '+ @Database  + ' at ' + convert(VARCHAR(20), GETDATE(), 14)
SET @SQL = 'Drop database ' + @Database
EXEC sp_executesql @SQL
PRINT 'Dropped DB => '+ @Database  + ' at ' + convert(VARCHAR(20), GETDATE(), 14)
PRINT ''

SET @SQL = 'exec master..sqlbackup N''-SQL "RESTORE DATABASE [' + @Database + '] ' 
SET @SQL = @SQL + 'FROM DISK = ''''' + @File + ''''' '
SET @SQL = @SQL + 'WITH STANDBY = ''''I:\UndoFile\' + @Database + '.und'''''

DECLARE @PhysicalName AS VARCHAR(255)
DECLARE @LogicalName AS VARCHAR(64)
DECLARE @FileType AS CHAR(1)

		DECLARE c1 CURSOR FAST_FORWARD READ_ONLY FOR
		SELECT LogicalName,PhysicalName,FileType FROM #Table

		OPEN c1

		FETCH NEXT FROM c1 INTO @LogicalName, @PhysicalName, @FileType

		WHILE @@FETCH_STATUS = 0
		BEGIN

			SET @SQL = @SQL + ', MOVE ''''' + @LogicalName + ''''' TO ''''' + @PhysicalName + ''''''
		
			FETCH NEXT FROM c1 INTO @LogicalName, @PhysicalName, @FileType 

		END

		CLOSE c1
		DEALLOCATE c1

SET @SQL = @SQL +  ', PASSWORD = ''''' + @Pass + '''''"'''

PRINT @SQL

EXEC sp_executesql @SQL
PRINT ''
PRINT 'Restored backup file ' + @File + ' to Database ' + @Database  + ' at ' + convert(VARCHAR(20), GETDATE(), 14)


DROP Table #Table
