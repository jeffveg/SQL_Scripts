/****** Object:  StoredProcedure [dbo].[sp_jsonlite]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE[dbo].[sp_jsonlite]
	@jsonliteCommand varchar(100) = '',
	@jsoninput varchar(max) = '',
	@flattenRecord bit = 0,
	@sqlUser varchar(100) = '',
	@sqlServer varchar(100) = '',
	@sqlDb varchar(100) = '',
	@sqlIsDSN bit = 0,
	@sqlDSNOrDriver varchar(100) = '',
	@outputs varchar(200) = '',
	@outputDb varchar(200) = 'ICEDW_Working',
	@help tinyint = 0
AS

SET NOCOUNT ON

BEGIN TRY
IF @help = 1
BEGIN
	PRINT 
		'@jsonliteCommand - one of the following as seen in the jsonlite documentation.' + CHAR(13) + CHAR(10) +
		'    validate, minify, prettify, fromJSON, toJSON, flatten' + CHAR(13) + CHAR(10) +
		'@jsoninput - your JSON string for use with fromJSON, a file name, or a sql select or exec' + CHAR(13) + CHAR(10) +
		'@flattenRecord - should the flatten command be applied?  See R jsonlite documentation' + CHAR(13) + CHAR(10) +
		'@sqlUser - a sql login you want to use to run the query in @sqlSelect.  You must use a sql login.  Windows auth is not possible yet' + CHAR(13) + CHAR(10) +

		'@sqlServer - a sql server name for use with toJSON' + CHAR(13) + CHAR(10) +
		'@sqlDb - the name of the database you want to run the query against.  Even if the database name is in your query, you still' + CHAR(13) + CHAR(10) +
		'    provide it here so that I can make a proper connection string' + CHAR(13) + CHAR(10) +
		'@sqlIsDSN - are you going to give me a DSN or a driver name in the @sqlDSNOrDriver' + CHAR(13) + CHAR(10) +
		'@sqlDSNOrDriver - the name of the driver, or a dsn to connect to the database with' + CHAR(13) + CHAR(10) +
		'@outputs - file names, db, screen' + CHAR(13) + CHAR(10) +
		'@outputDb - the database where the result should be written.  This is necessary even when going to screen' + CHAR(13) + CHAR(10) +
		'@help - how you got here!'
	RETURN(0)
END

SELECT @jsonliteCommand = LOWER(@jsonliteCommand)
SELECT @outputs = LOWER(@outputs)

INSERT ICEDW_Working..sp_jsonlite_output
EXEC sp_execute_external_script
	@language = N'R',
	@script = N'x <- parseJSON(input, cmd, recflat, output, outdb, dsndriver, server, db, user, isdsn)',
	@input_data_1 = N'',
	@params = N'@input varchar(max), @cmd varchar(100), @recflat bit, @user varchar(100), @server varchar(100), @db varchar(100), @isdsn bit, @dsndriver varchar(100), @output varchar(200), @outdb varchar(200)',
	@input = @jsoninput,
	@cmd = @jsonliteCommand,
	@recflat = @flattenRecord,
	@user = @sqlUser,
	@server = @sqlServer,
	@db = @sqlDb,
	@isdsn = @sqlIsDSN,
	@dsndriver = @sqlDSNOrDriver,
	@output = @outputs,
	@outdb = @OutputDb

	IF @outputs LIKE '%screen%'
	BEGIN
		EXEC('SELECT * FROM ' + @OutputDb + '..sp_jsonlite_output')
	END
END TRY
BEGIN CATCH
THROW;
END CATCH;
GO
