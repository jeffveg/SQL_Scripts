/****** Object:  StoredProcedure [dbo].[sp_DisplayTime]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_DisplayTime] (
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
