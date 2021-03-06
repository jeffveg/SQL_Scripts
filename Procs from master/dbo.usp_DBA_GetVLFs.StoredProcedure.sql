/****** Object:  StoredProcedure [dbo].[usp_DBA_GetVLFs]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_DBA_GetVLFs]
AS

DECLARE @query varchar(1000),
 @dbname varchar(1000),
 @count int

SET NOCOUNT ON

DECLARE csr CURSOR FAST_FORWARD READ_ONLY
FOR
SELECT name
FROM sys.databases

DECLARE @loginfo TABLE (
	dbname varchar(100),
	num_of_rows int
)

OPEN csr

FETCH NEXT FROM csr INTO @dbname

WHILE (@@fetch_status <> -1)
BEGIN

DECLARE @log_info TABLE (
    RecoveryUnitId  INT NOT NULL, 
    FileId  INT NOT NULL, 
    FileSize BIGINT NOT NULL, 
    StartOffset BIGINT NOT NULL, 
    SeqNo INT NOT NULL, 
    Status INT NOT NULL, 
    Parity INT NOT NULL, 
    CreateLSN DECIMAL (25,0)
)

SET @query = 'DBCC loginfo (' + '''' + @dbname + ''') '

INSERT INTO @log_info
EXEC (@query)

SET @count = @@rowcount

INSERT @loginfo
VALUES(@dbname, @count)

FETCH NEXT FROM csr INTO @dbname

END

CLOSE csr
DEALLOCATE csr

DECLARE @logSpace TABLE (
	DatabaseName VARCHAR(75)
	,LogSizeMB DECIMAL(9,2)
	,LogSpaceUsedMB DECIMAL(9,2)
	,[Status] INT
)
INSERT @logSpace
EXEC('DBCC SQLPERF(LOGSPACE)')

SELECT 
	@@SERVERNAME AS [ServerName]
	,[i].[dbname]
	,[s].[LogSizeMB]
	,[s].[LogSpaceUsedMB]
	,[i].[num_of_rows] AS [NumOfVLFs]
FROM @loginfo [i]
JOIN @logSpace [s] ON [i].[dbname] = [s].[DatabaseName]
--WHERE num_of_rows >= 50 --My rule of thumb is 50 VLFs. Your mileage may vary.
ORDER BY [i].[dbname]

GO
