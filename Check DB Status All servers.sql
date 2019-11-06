SET NOCOUNT ON

DECLARE @SQL NVARCHAR(2000)
DECLARE @Servers TABLE (Srv VARCHAR(100),Ver INT, DrP CHAR(3))
DECLARE @CurSvr VARCHAR(100)
DECLARE @SrvVer INT
DECLARE @DrP CHAR(3)

DECLARE @ServerList TABLE
    (
     DevOrProd VARCHAR(10)
   , ServerName VARCHAR(100)
   , DatabaseName NVARCHAR(128) 
   , DBStatus INT
    ) 

INSERT  INTO @Servers VALUES  ('AFSDEPOT',10,'PRD')
INSERT  INTO @Servers VALUES  ('OTGMONSQL01',10,'PRD')
INSERT  INTO @Servers VALUES  ('OTGRPT03',10,'PRD')
INSERT  INTO @Servers VALUES  ('OTGSQL01',10,'PRD')
INSERT  INTO @Servers VALUES  ('OTGSQL03',10,'PRD')
INSERT  INTO @Servers VALUES  ('OTGSQL04',10,'PRD')
INSERT  INTO @Servers VALUES  ('OTGSQL05',10,'PRD')
INSERT  INTO @Servers VALUES  ('OTGSQL06',10,'PRD')
INSERT  INTO @Servers VALUES  ('OTGSQL07',10,'PRD')
INSERT  INTO @Servers VALUES  ('PHXDBDB02',10,'PRD')
INSERT  INTO @Servers VALUES  ('PHXDFDB01',10,'PRD')
INSERT  INTO @Servers VALUES  ('EMPAPP01',8,'PRD')
INSERT  INTO @Servers VALUES  ('FIRSKL01',8,'DMZ')
INSERT  INTO @Servers VALUES  ('OTGAPP05',8,'PRD')
INSERT  INTO @Servers VALUES  ('OTGAPP16',8,'PRD')
INSERT  INTO @Servers VALUES  ('OTGETL01',8,'PRD')
INSERT  INTO @Servers VALUES  ('OTGETL02',8,'PRD')
INSERT  INTO @Servers VALUES  ('OTGRPT01',8,'PRD')
INSERT  INTO @Servers VALUES  ('OTGSKL08',8,'PRD')
INSERT  INTO @Servers VALUES  ('OTGSKL09',8,'PRD')
INSERT  INTO @Servers VALUES  ('OTGSQL02',8,'PRD')
INSERT  INTO @Servers VALUES  ('OTGTRT02',8,'PRD')
INSERT  INTO @Servers VALUES  ('SKL05',8,'PRD')
INSERT INTO @servers VALUES ('AFSTSTDPT02',8,'DEV')
INSERT INTO @servers VALUES ('AFSTSTSQL01',8,'DEV')
INSERT INTO @servers VALUES ('DEVSKL02',8,'DEV')
INSERT INTO @servers VALUES ('PHXDFDB03',8,'DEV')
INSERT INTO @servers VALUES ('DEVSQL03',8,'DEV')
INSERT INTO @servers VALUES ('PHXDFDB04',8,'DEV')
INSERT INTO @servers VALUES ('PHXDFDT01',8,'DEV')
INSERT INTO @servers VALUES ('DEVSQL01',8,'DEV')
INSERT INTO @servers VALUES ('PHXDBDB05',8,'PRD')
INSERT INTO @servers VALUES ('[172.16.3.20]',10,'DMZ')


--  sp_addlinkedserver 'PHXDBDB05'

DECLARE c1 CURSOR FAST_FORWARD READ_ONLY
FOR
SELECT  Srv,Ver,DrP
FROM    @Servers
ORDER BY 1

OPEN c1

FETCH NEXT FROM c1 INTO @cursvr,@SrvVer,@DrP

WHILE @@FETCH_STATUS = 0 
    BEGIN


       SET @SQL = 'Select ''' + @DrP+ ''',''' + @CurSvr + ''', name, status from ' + @CurSvr + '.master.dbo.sysdatabases'


        INSERT  INTO @ServerList
                EXEC sp_executesql @Sql
                PRINT  @Sql

        FETCH NEXT FROM c1 INTO @cursvr,@SrvVer,@DrP
end

CLOSE c1
DEALLOCATE c1

SELECT *      
	 , DBStatus & 256 Suspect
	  --, DBStatus & 1 autoclose 
	  --, DBStatus & 4 select_into_bulkcopy
	  --, DBStatus & 8 trunc_log_on_chkpt
	  --, DBStatus & 16 TORN_PAGE_DETECTION
	  , DBStatus & 32 loading 
	  , DBStatus & 64 pre_recovery 
	  , DBStatus & 128 recovering 
	  , DBStatus & 512 offline 
	  , DBStatus & 1024 read_only 
	  , DBStatus & 2048 dbo_use_only
	  , DBStatus & 4096 SINGLE_USER
	  , DBStatus & 32768 emergency_mode
	  --, DBStatus & 4194304 autoshrink
	  --, DBStatus & 1073741824 cleanly_shutdown
FROM    @ServerList
ORDER BY DevOrProd,ServerName
      , DatabaseName
      

