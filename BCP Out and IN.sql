



DECLARE @strSQL AS NVARCHAR(1024)
DECLARE @strTblName AS VARCHAR(50)
DECLARE @strdbname AS varchar(50)
SET @strdbname = 'NoCall'

-- =============================================
-- Declare and using a READ_ONLY cursor
-- =============================================

--DECLARE Archive CURSOR FOR 

EXEC('DECLARE Archive CURSOR FOR 
SELECT name FROM ' + @strDBName + '..sysobjects WHERE type = ''U'' 
AND ((OBJECTPROPERTY(OBJECT_ID(name), ''IsMSShipped'') = 0) OR (OBJECT_ID(name) IS NULL))
ORDER BY name')

SET NOCOUNT ON

OPEN Archive
FETCH NEXT FROM Archive INTO @strTblName
WHILE (@@fetch_status <> -1)
BEGIN
 IF (@@fetch_status <> -2)
 BEGIN

  SET @strSQL = 'bcp ' + @strDBName + '..'+ @strTblName + ' Out ' + 'd:\BCPOUT' + '\' + @strTblName + '.txt -N -q -o' + 'd:\BCPOUT' + '\' + @strTblName + '.log -S' + ' PHXDBDT11' + ' -T'
  print @strSQL
  EXEC master..xp_cmdshell @strSQL

END
 FETCH NEXT FROM Archive INTO @strTblName
END
CLOSE Archive
DEALLOCATE Archive
SET NOCOUNT OFF




--------------------------------------------------------
-- Back in 
-------------------------------------------------------
--DECLARE @strSQL AS NVARCHAR(1024)
--DECLARE @strTblName AS VARCHAR(50)
--DECLARE @strdbname AS varchar(50)
SET @strdbname = 'NoCall_Stage'

-- =============================================
-- Declare and using a READ_ONLY cursor
-- =============================================

--DECLARE Archive CURSOR FOR 

EXEC('DECLARE Archive CURSOR FOR 
SELECT name FROM ' + @strDBName + '..sysobjects WHERE type = ''U'' 
AND ((OBJECTPROPERTY(OBJECT_ID(name), ''IsMSShipped'') = 0) OR (OBJECT_ID(name) IS NULL))
ORDER BY name')

SET NOCOUNT ON


OPEN Archive
FETCH NEXT FROM Archive INTO @strTblName
WHILE (@@fetch_status <> -1)
BEGIN
 IF (@@fetch_status <> -2)
 BEGIN
-- Turn on IDENTITY_INSERT if the table has it
	if exists (
				select 
		tn.name
	from 
		sysobjects tn
		join syscolumns cn on 
			tn.id = cn.id
	where 
		autoval is not null 
		and tn.name = @strTblName
	)
  begin
	set @Strsql = 'SET IDENTITY_INSERT ' + @strDBName + '..'+ @strTblName + ' ON'
	exec sp_executesql @Strsql
  end 

-- Truncate tables
	set @Strsql = 'TRUNCATE TABLE ' + @strDBName + '..'+ @strTblName 
	exec sp_executesql @Strsql
 

  SET @strSQL = 'bcp ' + @strDBName + '..'+ @strTblName + ' in ' + 'd:\BCPOUT' + '\' + @strTblName + '.txt -N -q -o' + 'd:\BCPOUT' + '\' + @strTblName + '_In.log -S' + ' PHXDBDT11' + ' -T'
  print @strSQL
  EXEC master..xp_cmdshell @strSQL

-- Turn off IDENTITY_INSERT if the table had it
if exists (
				select 
		tn.name
	from 
		sysobjects tn
		join syscolumns cn on 
			tn.id = cn.id
	where 
		autoval is not null 
		and tn.name = @strTblName
	)
  begin
	set @Strsql = 'SET IDENTITY_INSERT ' + @strDBName + '..'+ @strTblName + ' OFF'
	exec sp_executesql @Strsql
   end


 END
 FETCH NEXT FROM Archive INTO @strTblName
END
CLOSE Archive
DEALLOCATE Archive
SET NOCOUNT OFF




