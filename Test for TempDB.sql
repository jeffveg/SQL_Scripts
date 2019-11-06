USE [master]
GO

RAISERROR (
		'Dropping Databse JeffTestTemp'
		, 0
		, 0
		);

BEGIN TRY
	DROP DATABASE [JeffTest];
END TRY

BEGIN CATCH
	RAISERROR (
			'Databse JeffTestTemp does not exist'
			, 0
			, 0
			);
END CATCH

RAISERROR (
		'Create Database JeffTestTemp'
		, 0
		, 0
		);
GO

CREATE DATABASE JeffTestTemp CONTAINMENT = NONE ON PRIMARY (
	NAME = N'JeffTestTemp_Data'
	, FILENAME = N'D:\SQLData\JeffTestTemp_Data.mdf'
	, SIZE = 1 GB
	, MAXSIZE = UNLIMITED
	, FILEGROWTH = 1 GB
	) LOG ON (
	NAME = N'JeffTestTemp_Log'
	, FILENAME = N'L:\SQLLogs\JeffTestTemp_Log.ldf'
	, SIZE = 1 GB
	, MAXSIZE = UNLIMITED
	, FILEGROWTH = 1 GB
	);
GO

USE JeffTestTemp

RAISERROR (
		'Create Timing Proc'
		, 0
		, 0
		);
GO

-- Create time procedure
CREATE PROCEDURE DisplayTime (
	@StartTime DATETIME2
	, @StepStartTime DATETIME2
	)
AS
BEGIN
	DECLARE @Now DATETIME2
		, @Elapsed VARCHAR(100)
		, @StepTime VARCHAR(100)
		, @TempTime INT;

	SET @Now = SYSDATETIME();

	--PRINT 'Start: ' + convert(VARCHAR(20), @StartTime, 114) + ' Step: ' + convert(VARCHAR(20), @StepStartTime, 114) + ' Now: ' + convert(VARCHAR(20), @Now, 114);
	IF DATEDIFF(SECOND, @StartTime, @Now) < 2
	BEGIN
		SET @TempTime = DATEDIFF(MILLISECOND, @StartTime, @Now);
		SET @Elapsed = 'Running time: ' + cast(@TempTime AS VARCHAR(100)) + ' Milliseconds';
	END
	ELSE IF DATEDIFF(minute, @StartTime, @Now) < 2
	BEGIN
		SET @TempTime = DATEDIFF(MILLISECOND, @StartTime, @Now);
		SET @Elapsed = 'Running time: ' + cast(@TempTime / 1000 AS VARCHAR(100)) + ' Seconds ' + cast(@TempTime - (@TempTime / 1000) * 1000 AS VARCHAR(100)) + ' Milliseconds';
	END
	ELSE
	BEGIN
		SET @TempTime = DATEDIFF(second, @StartTime, @Now);
		SET @Elapsed = 'Running time: ' + cast(@TempTime / 60 AS VARCHAR(100)) + ' Minutes ' + cast(@TempTime - (@TempTime / 60) * 60 AS VARCHAR(100)) + ' Seconds';
	END

	IF DATEDIFF(MILLISECOND, @StepStartTime, @Now) < 2
	BEGIN
		SET @TempTime = DATEDIFF(microsecond, @StepStartTime, @Now);
		SET @StepTime = 'Step: ' + cast(@TempTime AS VARCHAR(100)) + ' Microsecond';
	END
	ELSE IF DATEDIFF(SECOND, @StepStartTime, @Now) < 2
	BEGIN
		SET @TempTime = DATEDIFF(MILLISECOND, @StepStartTime, @Now);
		SET @StepTime = 'Step: ' + cast(@TempTime AS VARCHAR(100)) + ' Milliseconds';
	END
	ELSE IF DATEDIFF(minute, @StepStartTime, @Now) < 2
	BEGIN
		SET @TempTime = DATEDIFF(MILLISECOND, @StepStartTime, @Now);
		SET @StepTime = 'Step: ' + cast(@TempTime / 1000 AS VARCHAR(100)) + ' Seconds ' + cast(@TempTime - (@TempTime / 1000) * 1000 AS VARCHAR(100)) + ' Milliseconds';
	END
	ELSE
	BEGIN
		SET @TempTime = DATEDIFF(second, @StepStartTime, @Now);
		SET @StepTime = 'Step: ' + cast(@TempTime / 60 AS VARCHAR(100)) + ' Minutes ' + cast(@TempTime - (@TempTime / 60) * 60 AS VARCHAR(100)) + ' Seconds';
	END

	DECLARE @Message VARCHAR(100);

	SET @Message = @StepTime + ' - ' + @Elapsed;

	RAISERROR (
			@Message
			, 0
			, 0
			)
	WITH NOWAIT;
END
GO

------------------------------------------------------------------------------------------------
SET NOCOUNT ON

RAISERROR (
		'Getting TempDB stats'
		, 0
		, 0
		);

SELECT '1 First Run' Run
	, files.physical_name
	, files.NAME
	, stats.num_of_writes
	, (1.0 * stats.io_stall_write_ms / stats.num_of_writes) AS avg_write_stall_ms
	, stats.num_of_reads
	, (1.0 * stats.io_stall_read_ms / stats.num_of_reads) AS avg_read_stall_ms
INTO TempStats
FROM sys.dm_io_virtual_file_stats(2, NULL) AS stats
INNER JOIN master.sys.master_files AS files
	ON stats.database_id = files.database_id
		AND stats.file_id = files.file_id
WHERE files.type_desc = 'ROWS';

DECLARE @StartTime DATETIME2
	, @StepStartTime DATETIME2
	, @Message VARCHAR(100);

RAISERROR (
		'Starting Timer'
		, 0
		, 0
		);

SET @StartTime = SYSDATETIME();
SET @StepStartTime = SYSDATETIME();

RAISERROR (
		'Creating Table TestBase'
		, 0
		, 0
		);

CREATE TABLE TestBase (
	id INT not null 
	, rand_integer INT
	, rand_number NUMERIC(18, 9)
	, rand_datetime DATETIME
	, rand_string VARCHAR(80)
	);

EXEC DisplayTime @StartTime
	, @StepStartTime;

SET @StepStartTime = SYSDATETIME();

RAISERROR (
		'Insert rows with random values'
		, 0
		, 0
		);


INSERT INTO TestBase (id)
SELECT TOP 5000000 row_number() OVER (
		ORDER BY t1.number
		) AS N
FROM master..spt_values t1
CROSS JOIN master..spt_values t2
CROSS JOIN master..spt_values t3


UPDATE TestBase
	SET rand_integer = ROUND(2000000 * RAND(id) - 1000000, 0)
		, rand_number = ROUND(2000000 * RAND(id) - 1000000, 9)
		, rand_datetime = CONVERT(DATETIME, ROUND(60000 * RAND(id) - 30000, 9))
		, rand_string =  RAND(id)
	

SET @Message = substring(convert(VARCHAR(20), cast(@@Rowcount AS MONEY), 1), 1, len(convert(VARCHAR(20), cast(@@Rowcount AS MONEY), 1)) - 3) + ' Rows inserted';

		RAISERROR (
				@message
				, 0
				, 0
				);


EXEC DisplayTime @StartTime
	, @StepStartTime;

SET @StepStartTime = SYSDATETIME();

RAISERROR (
		'Creating Index TestBase'
		, 0
		, 0
		);

CREATE INDEX ix1 ON TestBase (id)
	WITH (SORT_IN_TEMPDB = ON)

CREATE INDEX ix2 ON TestBase (rand_integer)
	WITH (SORT_IN_TEMPDB = ON)

CREATE INDEX ix3 ON TestBase (rand_string)
	WITH (SORT_IN_TEMPDB = ON)

EXEC DisplayTime @StartTime
	, @StepStartTime;

RAISERROR (
		'Making Temp Datbase'
		, 0
		, 0
		);

BEGIN TRY
	DROP TABLE #TempTest
END TRY

BEGIN CATCH
	SET @message = ''
END CATCH

SELECT *
INTO #TempTest
FROM TestBase

insert into #TempTest
SELECT *
FROM TestBase



EXEC DisplayTime @StartTime
	, @StepStartTime;

SET @StepStartTime = SYSDATETIME();



RAISERROR (
		'Creating Index #TempTest'
		, 0
		, 0
		);

CREATE INDEX ixtt1 ON #TempTest (rand_number)
	WITH (SORT_IN_TEMPDB = ON)

CREATE INDEX ixtt2 ON #TempTest (rand_integer)
	WITH (SORT_IN_TEMPDB = ON)

CREATE INDEX ixtt3 ON #TempTest (rand_string)
	WITH (SORT_IN_TEMPDB = ON)


EXEC DisplayTime @StartTime
	, @StepStartTime;

SET @StepStartTime = SYSDATETIME();





RAISERROR (
		'Update Temp Datbase'
		, 0
		, 0
		);


update #TempTest set  rand_integer = rand_integer + 1
update #TempTest set rand_number=	 rand_number / 2
update #TempTest set rand_datetime = dateadd(second,40,rand_datetime  )
update #TempTest set  rand_string = replace(rand_string ,'a','@')
	

EXEC DisplayTime @StartTime
	, @StepStartTime;

SET @StepStartTime = SYSDATETIME();

RAISERROR (
		'Getting TempDB stats'
		, 0
		, 0
		)

INSERT INTO TempStats
SELECT '2 Finish' Run
	, files.physical_name
	, files.NAME
	, stats.num_of_writes
	, (1.0 * stats.io_stall_write_ms / stats.num_of_writes) AS avg_write_stall_ms
	, stats.num_of_reads
	, (1.0 * stats.io_stall_read_ms / stats.num_of_reads) AS avg_read_stall_ms
FROM sys.dm_io_virtual_file_stats(2, NULL) AS stats
INNER JOIN master.sys.master_files AS files
	ON stats.database_id = files.database_id
		AND stats.file_id = files.file_id
WHERE files.type_desc = 'ROWS'

SELECT cast(b.NAME AS CHAR(20)) NAME
	, a.num_of_writes - b.num_of_writes AS Diff_Write
	, cast(b.avg_write_stall_ms AS MONEY) avg_write_stall_ms_Before
	, cast(a.avg_write_stall_ms AS MONEY) avg_write_stall_ms_After
	, a.num_of_reads - b.num_of_reads AS Diff_Read
	, cast(b.avg_read_stall_ms AS MONEY) avg_read_stall_ms_Before
	, cast(a.avg_read_stall_ms AS MONEY) avg_read_stall_ms_After
FROM TempStats b
INNER JOIN TempStats a
	ON a.NAME = b.NAME
		AND a.run LIKE '2%'
WHERE b.run LIKE '1%'
ORDER BY NAME

USE [master]
GO

RAISERROR (
		'Dropping Databse JeffTestTemp'
		, 0
		, 0
		);

BEGIN TRY
	DROP DATABASE [JeffTestTemp];
END TRY

BEGIN CATCH
	RAISERROR (
			'Cannot drop databse JeffTestTemp'
			, 0
			, 0
			);
END CATCH