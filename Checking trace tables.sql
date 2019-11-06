USE JeffSchmidt

DECLARE @StartTime DATETIME

SELECT  @StartTime = StartTime
FROM    dbo.SKL05Trace
WHERE   RowNumber = null

SELECT  RowNumber
      , ApplicationName
      , NTUserName
      , LoginName
      , CPU
      , Reads
      , Writes
      , Duration
      , StartTime
      , CAST(Duration AS FLOAT) / 1000 Duration_in_Sec  /* this is for 2000  change to 1000000 for 2005/2008*/
      , CAST(Duration AS MONEY) / 60000 Duration_in_Min /* this is for 2000  change to 60000000 for 2005/2008*/
      , EndTime 
      , TextData
FROM    dbo.SKL05Trace WITH (READPAST)
WHERE   1 = 1
        AND LoginName = 'logon_hoaValidation'
        AND Duration > (SELECT  STDEV(duration) * 2
                        FROM    dbo.SKL05Trace WITH (READPAST)
                        WHERE   LoginName = 'logon_hoaValidation'
                                AND duration > 0)
ORDER BY RowNumber DESC

 
--SELECT *,  CAST(Duration AS money) / 60000000 Duration_in_Min FROM dbo.Otgsql04 WHERE ApplicationName = 'Visual CUT 11 R2'


IF @StartTime IS NULL 
    SELECT  @starttime = starttime
    FROM    SKL05Trace
    WHERE   duration = (SELECT  MAX(duration)
                        FROM    dbo.SKL05Trace WITH (READPAST)
                        WHERE   LoginName = 'logon_hoaValidation'
                                AND duration > 0
                                AND StartTime > DATEADD(mi, -30, GETDATE()))
 
 

SELECT  TextData
      , ApplicationName
      , NTUserName
      , LoginName
      , CPU
      , Reads
      , Writes
      , Duration
      , StartTime
      , CAST(Duration AS FLOAT) / 1000 Duration_in_Sec  /* this is for 2000  change to 1000000 for 2005/2008*/
      , EndTime
FROM    dbo.SKL05Trace
WHERE   StartTime <= @StartTime
        AND Duration > 0
        AND EndTime  >= @StartTime
        
        SELECT TOP 100 * FROM dbo.SKL05Trace WHERE StartTime > DATEADD( mi,-5,GETDATE()) ORDER BY 1 desc

        SELECT  STDEV(duration) * 2 StandDevDurationX2 , COUNT(*) Records, MAX(duration) MaxDuration, AVG(Duration) AvgDuration
                        FROM    dbo.SKL05Trace WITH (READPAST)
                        WHERE   LoginName = 'logon_hoaValidation'
                                AND duration > 0
        
        --SELECT * FROM dbo.SKL05Trace_20110303 WHERE LoginName = 'mds'
        --SELECT COUNT(*) FROM ValidationData d INNER JOIN ValidationFiles f ON d.FileId = f.FileID WHERE (f.PmcId = @P1) AND (d.LockBoxID = @P2) AND (AccountId = @P3)', @P2 output, @P3 output, @P4 output, N'@P1 nvarchar(4000) ,@P2 nvarchar(4000) ,@P3 nvarchar(4000) ', N'3502', N'44T1', N'0000000044121362' select @P1, @P2, @P3, @P4
        
      

/*

sp_spaceused SKL05Trace  
select * FROM SKL05Trace  ORDER BY 1 desc
*/

