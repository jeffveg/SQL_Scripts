/****** Object:  StoredProcedure [dbo].[MyForEach]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[MyForEach] (@CMD NVARCHAR(4000))
AS
SET NOCOUNT ON 
DECLARE @dbs CURSOR
	, @cmd2Run NVARCHAR(4000)
	, @db NVARCHAR(128)
	, @sp NVARCHAR(255) SET @dbs = CURSOR STATIC
FOR
SELECT NAME
FROM sys.databases
WHERE STATE = 0 /* State 0 = online */
	AND Source_Database_id IS NULL /* Is not a snapshot */

OPEN @dbs 

WHILE (1 = 1)
BEGIN
	FETCH @dbs
	INTO @db 

	IF @@FETCH_STATUS <> 0
		BREAK 

	SET @cmd2Run = replace(@CMD, '?', @db)
	SET @sp = quotename(@db) + N'.sys.sp_executesql'
	EXEC @sp @cmd2Run 

END 

GO
