/****** Object:  StoredProcedure [dbo].[sp_GetSqlSummary_R]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_GetSqlSummary_R]
	@iquery varchar(8000),
	@idb varchar(50) = 'ICEDW',
	@iuser varchar(50),
	@ipass varchar(50),
	@iserver varchar(50) = 'us-sv-dw',
	@idoCompare int = 0, 
	@iwriteToDb int = 0, 
	@idataLimit int = 0, 
	@ireturnOkColsFromComp int = 0, 
	@iuseColNamesForCompare int = 0, 
	@iuseSameConnForCompare int = 1, 
	@icompDb varchar(75) = '', 
	@icompTable varchar(75) = '', 
	@icompUser varchar(75) = '', 
	@icompPass varchar(75) = '', 
	@icompServer varchar(75) = ''
AS

EXEC sp_execute_external_script
	@language = N'R',
	@script = N'
		getSQLSummary <- function(
			query, db, user, pass, server, doCompare, writeToDb, dataLimit,
			returnOkColsFromComp, useColNamesForCompare, useSameConnForCompare,
			compDb, compTable, compUser, compPass, compServer) {

			# Load required libraries
			suppressMessages(suppressWarnings(library(''RODBC''))) # For database access
			suppressMessages(suppressWarnings(library(''dplyr''))) # For data frame manipulation

			if (missing(doCompare)) { doCompare <- 0 }
			if (missing(writeToDb)) { writeToDb <- 0 }
			if (missing(dataLimit)) { dataLimit <- 0 }
			if (missing(returnOkColsFromComp)) { returnOkColsFromComp <- 0 }
			if (missing(useColNamesForCompare)) { useColNamesForCompare <- 0 }
			if (missing(useSameConnForCompare)) { useSameConnForCompare <- 0 }
			if (missing(compDb)) { compDb <- "" }
			if (missing(compTable)) { compTable <- "" }
			if (missing(compUser)) { compUser <- "" }
			if (missing(compPass)) { compPass <- "" }
			if (missing(compServer)) { compServer <- "" }

			# Create a connection string as specified by the caller
			sqlConn <- paste0("Driver=SQL Server;Server=", server, ";Database=", db, ";Uid=", user, ";Pwd=", pass)
			# Prepare to connect to the databe using the connection string and query
			rxOdbcDat <- RxOdbcData(connectionString = sqlConn, sqlQuery = query)
			# Run the query and store the result in queryResult, which will be a data.frame
			queryResult <- rxImport(rxOdbcDat, overwrite = TRUE)
			# Get the maximum length of all columns in the the queryResult data.frame and convert
			# the resulting list to a data frame.  The data frame, after this will contain 1 row
			# Called MaxLength, which holds the maximum length of all rows returned in queryResult
			# There will be one column for every column returned in queryResult
			asColsMaxLen <- lapply(queryResult, function(x) max(nchar(iconv(x)))) %>% as.data.frame(row.names = "QueryColMaxLen")
			# Transpose that and save as different var
			asRowsMaxLen <- asColsMaxLen %>% t() %>% as.data.frame()
			# Add the transposed row names as an actual column of data
			asRowsMaxLen$QueryColName <- asRowsMaxLen %>% rownames()
			# Kill the rownames so that we have numbers instead
			rownames(asRowsMaxLen) <- NULL
			asRowsMaxLen$ORDINAL_POSITION <- as.integer(rownames(asRowsMaxLen))
			asRowsMaxLen$QueryColRDataType <- sapply(queryResult,class)
			# Rearrange the columns
			asRowsMaxLen <- asRowsMaxLen %>% select(ORDINAL_POSITION, QueryColName, QueryColMaxLen, QueryColRDataType)
			# Check to see how much data should be dealt with from here on
			# Could get a large data.frame that takes a long time to print or write all rows to db
			# So the user may want to limit functionality when appropriate
			if (dataLimit == 0) {
				dataLimit <- length(queryResult)
			} else {
				# Trim the number of rows in queryResult using the dataLimit
				queryResult <- head(queryResult, dataLimit)
			}

			# Run str and print it as well as resultSummary
			print(str(queryResult, list.len = length(queryResult)))
			print.table(summary(queryResult))

			# Do the compare to the table specified by parameter
			if (doCompare == 1) {
				connText <- if (useSameConnForCompare == 1) {
					sqlConn
				} else {
					paste0("Driver=SQL Server;Server=", compServer, ";Database=", compDb, ";Uid=", compUser, ";Pwd=", compPass)
				}
				compSqlConn <- odbcDriverConnect(connText)
				result <- sqlColumns(compSqlConn, compTable) %>%
					select(ORDINAL_POSITION, COLUMN_NAME, TYPE_NAME, COLUMN_SIZE, DECIMAL_DIGITS) %>%
					arrange(ORDINAL_POSITION)
				if (useColNamesForCompare == 1) {
					result <- full_join(result, asRowsMaxLen, by = c("COLUMN_NAME" = "QueryColName")) %>% select(TYPE_NAME, QueryColRDataType, COLUMN_NAME, COLUMN_SIZE, DECIMAL_DIGITS, QueryColMaxLen)
				} else {
					result <- full_join(result, asRowsMaxLen, by = c("ORDINAL_POSITION" = "ORDINAL_POSITION")) %>% select(ORDINAL_POSITION, TYPE_NAME, QueryColRDataType, COLUMN_NAME, COLUMN_SIZE, DECIMAL_DIGITS, QueryColMaxLen)
				}

				if (returnOkColsFromComp == 0) {
					result <- result %>% filter((!(TYPE_NAME == "bit" & QueryColRDataType == "logical")) & COLUMN_SIZE < QueryColMaxLen | (is.na(COLUMN_SIZE) | is.na(QueryColMaxLen)))
					if(dim(result)[1] == 0){
						message("All rows filtered out as matches.  Maybe I am wrong.  Try returnOkColsFromComp=1 to bring back the matches and check for yourself")
					}
				}
				close(compSqlConn)
			} else {
				result <- asRowsMaxLen
			}

			if (writeToDb == 1) {
				sqlWriteConn <- odbcDriverConnect(sqlConn)
				odbcClearError(sqlWriteConn)
				drop <- sqlQuery(sqlWriteConn,"DROP TABLE IF EXISTS ssQueryResult;DROP TABLE IF EXISTS ssAsColsMaxLen;DROP TABLE IF EXISTS ssAsRowsMaxLen;DROP TABLE IF EXISTS ssReturnResult;")
				sqlSave(sqlWriteConn, queryResult, tablename = "ssQueryResult", rownames = FALSE, safer = FALSE, append = FALSE, fast = TRUE)
				sqlSave(sqlWriteConn, asColsMaxLen, tablename = "ssAsColsMaxLen", rownames = FALSE, safer = FALSE, append = FALSE, fast = TRUE)
				sqlSave(sqlWriteConn, asRowsMaxLen, tablename = "ssAsRowsMaxLen", rownames = FALSE, safer = FALSE, append = FALSE, fast = TRUE)
				sqlSave(sqlWriteConn, result, tablename = "ssReturnResult", rownames = FALSE, safer = FALSE, append = FALSE, fast = TRUE)
				close(sqlWriteConn)
			}

			return(list(result=result))
		}

		results <- getSQLSummary(query, db, user, pass, server, doCompare, writeToDb, dataLimit, returnOkColsFromComp, useColNamesForCompare, useSameConnForCompare, compDb, compTable, compUser, compPass, compServer)
		
		if (exists("results") && is.list(results)) {
			OutputDataSet <- results$result
		} else stop("the R function must return a list")',
	@input_data_1 = N'',
	@params = N'@query varchar(max), @db varchar(max), @user varchar(max), @pass varchar(max), @server varchar(max), @doCompare int, @writeToDb int, @dataLimit int, @returnOkColsFromComp int, @useColNamesForCompare int, @useSameConnForCompare int, @compDb varchar(max), @compTable varchar(max), @compUser varchar(max), @compPass varchar(max), @compServer varchar(max)',
    @query = @iquery,
	@db = @idb,
	@user = @iuser,
	@pass = @ipass,
	@server = @iserver,
	@doCompare = @idoCompare,
	@writeToDb = @iwriteToDb,
	@dataLimit = @idataLimit,
	@returnOkColsFromComp = @ireturnOkColsFromComp,
	@useColNamesForCompare = @iuseColNamesForCompare,
	@useSameConnForCompare = @iuseSameConnForCompare,
	@compDb = @icompDb,	
	@compTable = @icompTable,
	@compUser = @icompUser,
	@compPass = @icompPass,
	@compServer = @icompServer
GO
