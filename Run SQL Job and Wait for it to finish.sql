DECLARE @LastID BIGINT
DECLARE @JobName VARCHAR(255)

SET @JobName = 'Load usp_Load_ValidationDataView'

SELECT  @LastID = MAX(S.instance_id)
FROM    msdb.dbo.sysjobhistory S
        JOIN msdb.dbo.sysjobs SJ
            ON S.job_id = SJ.job_id
WHERE   SJ.name = @JobName

EXEC msdb.dbo.sp_start_job @JobName

WHILE NOT EXISTS ( SELECT   *
                   FROM     msdb.dbo.sysjobhistory S
                            JOIN msdb.dbo.sysjobs SJ
                                ON S.job_id = SJ.job_id
                   WHERE    SJ.name = @JobName
                            AND S.instance_id > @LastID ) 
    BEGIN
        WAITFOR DELAY '00:00:01'
    END
