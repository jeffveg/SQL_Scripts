SET NOCOUNT ON

DECLARE @SQL NVARCHAR(2000)
DECLARE @Servers TABLE (Srv VARCHAR(100),Ver INT, DrP CHAR(3))
DECLARE @CurSvr VARCHAR(100)
DECLARE @SrvVer INT
DECLARE @DrP CHAR(3)

DECLARE @ServerList TABLE
    (
     ServerName VARCHAR(100)
   , JobName NVARCHAR(128) 
   , IsEnabled BIT
   , JobOwner NVARCHAR(128) 
   , step_id INT 
   , step_name NVARCHAR(128) 
   , category VARCHAR(100) 
   , ProxyName NVARCHAR(128)
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
INSERT  INTO @Servers VALUES  ('FIRSKL01',8,'PRD')
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

--  sp_addlinkedserver 'PHXDBDT03'

DECLARE c1 CURSOR FAST_FORWARD READ_ONLY
FOR
SELECT  Srv,Ver,DrP
FROM    @Servers
ORDER BY 1

OPEN c1

FETCH NEXT FROM c1 INTO @cursvr,@SrvVer,@DrP

WHILE @@FETCH_STATUS = 0 
    BEGIN


IF @SrvVer = 8 
       SET @SQL = 
'SELECT ''' + @DrP+ '-' + @CurSvr + '''
	  , j.name JobName
      , j.enabled
      , p2.name AS JobOwner
      , s.step_id
      , s.step_name
      , c.name
      , null as ProxyName
FROM    ' + @CurSvr + '.msdb.dbo.sysjobsteps s
        LEFT OUTER JOIN ' + @CurSvr + '.msdb.dbo.sysjobs_view j
            ON s.job_id = j.job_id
        LEFT OUTER JOIN ' + @CurSvr + '.master.dbo.syslogins p
            ON p.sid = owner_sid
        LEFT OUTER JOIN ' + @CurSvr + '.master.dbo.syslogins p2
            ON p2.sid = j.owner_sid
        LEFT OUTER JOIN ' + @CurSvr + '.msdb.dbo.syscategories c
            ON c.category_id = j.category_id'
else        
       SET @SQL = 
'SELECT ''' + @DrP+ '-' + @CurSvr + '''
	  , j.name JobName
      , j.enabled
      , p2.name AS JobOwner
      , s.step_id
      , s.step_name
      , c.name
      , x.name AS ProxyName
FROM    ' + @CurSvr + '.msdb.dbo.sysjobsteps s
        LEFT OUTER JOIN ' + @CurSvr
            + '.msdb.dbo.sysjobs_view j ON s.job_id = j.job_id
        left JOIN ' + @CurSvr
            + '.master.sys.server_principals p ON p.sid = owner_sid
        left JOIN ' + @CurSvr
            + '.master.sys.server_principals p2 ON p2.sid = j.owner_sid
        LEFT JOIN ' + @CurSvr
            + '.msdb.dbo.sysproxies x ON x.proxy_id = s.proxy_id 
        LEFT JOIN ' + @CurSvr
            + '.msdb.dbo.syscategories c ON c.category_id = j.category_id'

        INSERT  INTO @ServerList
                EXEC sp_executesql @Sql

        FETCH NEXT FROM c1 INTO @cursvr,@SrvVer,@DrP

    END

CLOSE c1
DEALLOCATE c1

SELECT  *
FROM    @ServerList
ORDER BY ServerName
      , JobName
      , step_id
      
-- NTBANK\svcSQLJob