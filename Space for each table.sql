DECLARE @updateusage VARCHAR(10)

-- less accruate but faster
SET @updateusage = 'false'
--More Accurate but much longer run time
--SET @updateusage = 'true'

/* Quick
CREATE TABLE #Temp (
	[Name] VARCHAR(100)
	,[Rows] INT
	,reserved VARCHAR(30)
	,data VARCHAR(30)
	,index_Size VARCHAR(100)
	,unused VARCHAR(30)
	)

INSERT INTO #temp
EXEC sp_msforeachtable 'sp_Spaceused "?"'

SELECT *
FROM #temp
ORDER BY CAST(LEFT(Reserved, LEN(reserved) - 3) AS INT) DESC

DROP TABLE #temp
*/


CREATE TABLE #TABLE_SPACE_WORK (
	TABLE_NAME SYSNAME NOT NULL
	,TABLE_ROWS NUMERIC(18, 0) NOT NULL
	,RESERVED VARCHAR(50) NOT NULL
	,DATA VARCHAR(50) NOT NULL
	,INDEX_SIZE VARCHAR(50) NOT NULL
	,UNUSED VARCHAR(50) NOT NULL
	)

CREATE TABLE #TABLE_SPACE_USED (
	Seq INT NOT NULL IDENTITY(1, 1) PRIMARY KEY CLUSTERED
	,TABLE_NAME SYSNAME NOT NULL
	,TABLE_ROWS NUMERIC(18, 0) NOT NULL
	,RESERVED VARCHAR(50) NOT NULL
	,DATA VARCHAR(50) NOT NULL
	,INDEX_SIZE VARCHAR(50) NOT NULL
	,UNUSED VARCHAR(50) NOT NULL
	)

CREATE TABLE #TABLE_SPACE (
	Seq INT NOT NULL IDENTITY(1, 1) PRIMARY KEY CLUSTERED
	,TABLE_NAME SYSNAME NOT NULL
	,TABLE_ROWS Bigint NOT NULL
	,RESERVED bigint NOT NULL
	,DATA bigint NOT NULL
	,INDEX_SIZE bigint NOT NULL
	,UNUSED bigint NOT NULL
	,USED_MB NUMERIC(18, 4) NOT NULL
	,USED_GB NUMERIC(18, 4) NOT NULL
	,AVERAGE_BYTES_PER_ROW NUMERIC(18, 5) NULL
	,AVERAGE_DATA_BYTES_PER_ROW NUMERIC(18, 5) NULL
	,AVERAGE_INDEX_BYTES_PER_ROW NUMERIC(18, 5) NULL
	,AVERAGE_UNUSED_BYTES_PER_ROW NUMERIC(18, 5) NULL
	)

DECLARE @fetch_status INT
DECLARE @proc VARCHAR(200)
DECLARE @Brackets VARCHAR(200)

SELECT @proc = RTRIM(DB_NAME()) + '.dbo.sp_spaceused'

DECLARE Cur_Cursor CURSOR LOCAL
FOR
SELECT TABLE_NAME = QUOTENAME(RTRIM(TABLE_SCHEMA)) + '.' + QUOTENAME(RTRIM(TABLE_NAME))
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY 1

OPEN Cur_Cursor

DECLARE @TABLE_NAME VARCHAR(200)

SELECT @fetch_status = 0

WHILE @fetch_status = 0
BEGIN
	FETCH NEXT
	FROM Cur_Cursor
	INTO @TABLE_NAME

	SELECT @fetch_status = @@fetch_status

	IF @fetch_status <> 0
	BEGIN
		CONTINUE
	END

	TRUNCATE TABLE #TABLE_SPACE_WORK



	INSERT INTO #TABLE_SPACE_WORK (
		TABLE_NAME
		,TABLE_ROWS
		,RESERVED
		,DATA
		,INDEX_SIZE
		,UNUSED
		)
	EXEC @proc @objname = @TABLE_NAME
		,@updateusage = @updateusage

	-- Needed to work with SQL 7
	UPDATE #TABLE_SPACE_WORK
	SET TABLE_NAME = @TABLE_NAME

	INSERT INTO #TABLE_SPACE_USED (
		TABLE_NAME
		,TABLE_ROWS
		,RESERVED
		,DATA
		,INDEX_SIZE
		,UNUSED
		)
	SELECT TABLE_NAME
		,TABLE_ROWS
		,RESERVED
		,DATA
		,INDEX_SIZE
		,UNUSED
	FROM #TABLE_SPACE_WORK
END

--While end
CLOSE Cur_Cursor

DEALLOCATE Cur_Cursor

INSERT INTO #TABLE_SPACE (
	TABLE_NAME
	,TABLE_ROWS
	,RESERVED
	,DATA
	,INDEX_SIZE
	,UNUSED
	,USED_MB
	,USED_GB
	,AVERAGE_BYTES_PER_ROW
	,AVERAGE_DATA_BYTES_PER_ROW
	,AVERAGE_INDEX_BYTES_PER_ROW
	,AVERAGE_UNUSED_BYTES_PER_ROW
	)
SELECT REPLACE(REPLACE(TABLE_NAME,']',''),'[','')AS TABLE_NAME
	,TABLE_ROWS
	,RESERVED
	,DATA
	,INDEX_SIZE
	,UNUSED
	,USED_MB = ROUND(CONVERT(NUMERIC(25, 10), RESERVED) / CONVERT(NUMERIC(25, 10), 1024), 4)
	,USED_GB = ROUND(CONVERT(NUMERIC(25, 10), RESERVED) / CONVERT(NUMERIC(25, 10), 1024 * 1024), 4)
	,AVERAGE_BYTES_PER_ROW = CASE
		WHEN TABLE_ROWS <> 0
			THEN ROUND((1024.000000 * CONVERT(NUMERIC(25, 10), RESERVED)) / CONVERT(NUMERIC(25, 10), TABLE_ROWS), 5)
		ELSE NULL
		END
	,AVERAGE_DATA_BYTES_PER_ROW = CASE
		WHEN TABLE_ROWS <> 0
			THEN ROUND((1024.000000 * CONVERT(NUMERIC(25, 10), DATA)) / CONVERT(NUMERIC(25, 10), TABLE_ROWS), 5)
		ELSE NULL
		END
	,AVERAGE_INDEX_BYTES_PER_ROW = CASE
		WHEN TABLE_ROWS <> 0
			THEN ROUND((1024.000000 * CONVERT(NUMERIC(25, 10), INDEX_SIZE)) / CONVERT(NUMERIC(25, 10), TABLE_ROWS), 5)
		ELSE NULL
		END
	,AVERAGE_UNUSED_BYTES_PER_ROW = CASE
		WHEN TABLE_ROWS <> 0
			THEN ROUND((1024.000000 * CONVERT(NUMERIC(25, 10), UNUSED)) / CONVERT(NUMERIC(25, 10), TABLE_ROWS), 5)
		ELSE NULL
		END
FROM (
	SELECT TABLE_NAME
		,TABLE_ROWS
		,RESERVED = CONVERT(bigint, RTRIM(REPLACE(RESERVED, 'KB', '')))
		,DATA = CONVERT(bigint, RTRIM(REPLACE(DATA, 'KB', '')))
		,INDEX_SIZE = CONVERT(bigint, RTRIM(REPLACE(INDEX_SIZE, 'KB', '')))
		,UNUSED = CONVERT(bigint, RTRIM(REPLACE(UNUSED, 'KB', '')))
	FROM #TABLE_SPACE_USED aa
	) a
ORDER BY TABLE_NAME

PRINT 'Show results in descending order by size in MB'

SELECT *
FROM #TABLE_SPACE
ORDER BY USED_MB DESC
GO

DROP TABLE #TABLE_SPACE_WORK

DROP TABLE #TABLE_SPACE_USED

DROP TABLE #TABLE_SPACE

--------------------------------------------------------
-- Script to analyze table space usage using the
-- output from the sp_spaceused stored procedure
-- Works with SQL 7.0, 2000, and 2005
SET NOCOUNT ON

PRINT 'Show Size, Space Used, Unused Space, Type, and Name of all database files'

SELECT [FileSizeMB] = CONVERT(NUMERIC(10, 2), SUM(ROUND(a.size / 128., 2)))
	,[UsedSpaceMB] = CONVERT(NUMERIC(10, 2), SUM(ROUND(FILEPROPERTY(a.NAME, 'SpaceUsed') / 128., 2)))
	,[UnusedSpaceMB] = CONVERT(NUMERIC(10, 2), SUM(ROUND((a.size - FILEPROPERTY(a.NAME, 'SpaceUsed')) / 128., 2)))
	,[Type] = CASE
		WHEN a.groupid IS NULL
			THEN ''
		WHEN a.groupid = 0
			THEN 'Log'
		ELSE 'Data'
		END
	,[DBFileName] = ISNULL(a.NAME, '*** Total for all files ***')
FROM sysfiles a
GROUP BY groupid
	,a.NAME
WITH ROLLUP
HAVING a.groupid IS NULL
	OR a.NAME IS NOT NULL
ORDER BY CASE
		WHEN a.groupid IS NULL
			THEN 99
		WHEN a.groupid = 0
			THEN 0
		ELSE 1
		END
	,a.groupid
	,CASE
		WHEN a.NAME IS NULL
			THEN 99
		ELSE 0
		END
	,a.NAME
