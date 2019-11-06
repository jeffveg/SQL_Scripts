USE msdb
SET NOCOUNT ON 

DECLARE @JobName NVARCHAR(100)
DECLARE @OrgUserID VARBINARY(85)
DECLARE @OrgUserName VARCHAR(100)
DECLARE @StepId INT 
DECLARE @command NVARCHAR(100)
DECLARE @proxy_name NVARCHAR(100)
DECLARE @StepName VARCHAR(100)
SET @proxy_name = N'Proxy_svcSQLJobs' 

PRINT 'Start of Job Update ---------------------------------------------'
PRINT Getdate()
WHILE (SELECT   COUNT(*)
       FROM     dbo.sysjobs_view
       WHERE    owner_sid IN (SELECT    sid
                              FROM      sys.server_principals
                              WHERE     name LIKE '%sqluser'
                                        OR name LIKE '%skluser')) > 0 
    BEGIN 
PRINT '-----------------------------------------------------------------'
        SELECT TOP 1
                @JobName = Name
                , @OrgUserID = owner_sid
                        FROM    dbo.sysjobs_view
        WHERE   owner_sid IN (SELECT    sid
                              FROM      sys.server_principals
                              WHERE     name LIKE '%sqluser'
                                        OR name LIKE '%skluser')
        ORDER BY name

		SELECT @OrgUserName = name FROM sys.server_principals WHERE sid = @OrgUserID

        PRINT 'Changing Job ' + @JobName
        PRINT 'Orginal Owner ' + @OrgUserName
  
        EXEC msdb.dbo.sp_update_job @job_name = @JobName,
            @owner_login_name = N'NTBANK\svcSQLJob'


        WHILE (SELECT   COUNT(*)
               FROM     dbo.sysjobsteps s
                        LEFT OUTER JOIN sysjobs_view j
                            ON s.job_id = j.job_id
               WHERE    subsystem = 'SSIS'
                        AND ISNULL(proxy_id, -1) <> (SELECT proxy_id
                                                     FROM   dbo.sysproxies
                                                     WHERE  name = 'Proxy_svcSQLJobs')
                        AND (owner_sid IN (SELECT   sid
                                           FROM     sys.server_principals
                                           WHERE    name LIKE '%svcSQLJob'))) > 0 
            BEGIN 


                SELECT TOP 1
                        @StepId = s.step_id
                      , @command = s.command
                      , @StepName = s.step_name
                FROM    dbo.sysjobsteps s
                        LEFT OUTER JOIN sysjobs_view j
                            ON s.job_id = j.job_id
                WHERE   subsystem = 'SSIS'
                        AND ISNULL(proxy_id, -1) <> (SELECT proxy_id
                                                     FROM   dbo.sysproxies
                                                     WHERE  name = 'Proxy_svcSQLJobs')
                        AND (owner_sid IN (SELECT   sid
                                           FROM     sys.server_principals
                                           WHERE    name LIKE '%svcSQLJob'))
                ORDER BY j.name
                      , s.step_id
      
                PRINT 'Changing Proxy for Job ' + @JobName + ' Step Named '
                    + @StepName 
      
                EXEC msdb.dbo.sp_update_jobstep @job_name = @JobName,
                    @step_id = @StepId, @command = @command,
                    @proxy_name = N'Proxy_svcSQLJobs' 
            END
        PRINT '-----------------------------------------------------------------'
    END
    
PRINT 'End of Job Update -----------------------------------------------'
PRINT Getdate()
