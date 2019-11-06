/* Restore */
DECLARE  @RemoteBAKFileName NVARCHAR(2000), @LocalBAKFileName NVARCHAR(2000), @DBName VARCHAR(255)
		,@DataFilePath NVARCHAR(2000), @LogFilePath NVARCHAR(2000), @COMPATIBILITY_LEVEL varchar(4), @SimpleMode BIT

SET @DBName = 'REGCOM'
SET @RemoteBAKFileName = '\\ohcoldbd0041.sic.nwie.net\e$\' + @Dbname + '.bak'
SET @LocalBAKFileName = 'e:\' + @Dbname + '.bak'
SET @DataFilePath = 'N:\Microsoft SQL Server\MSSQL10_50.SQA2008\MSSQL\DATA\'
SET @LogFilePath = 'N:\Microsoft SQL Server\MSSQL10_50.SQA2008\MSSQL\LOG\'
SET @COMPATIBILITY_LEVEL = '100'
SET @SimpleMode = 'TRUE'

/*******************************************/

/* See if we can See the cmd shell setting*/
DECLARE @AdvanceOptions INT
DECLARE @CmdShell INT
CREATE TABLE #Configure
    (
     NAME SYSNAME
   , [Min] INT
   , [Max] INT
   , Config_Value INT
   , Run_value INT
    )
    
INSERT  INTO #Configure
        (NAME
       , Min
       , Max
       , Config_Value
       , Run_value
        )
        EXEC sp_configure 'show advanced options'

SELECT  @AdvanceOptions = Config_Value
FROM    #Configure

/* Set Advance options if needed */
IF @AdvanceOptions = 0 
    BEGIN
        EXEC sp_configure 'show advanced options', 1
        RECONFIGURE
    END

DELETE  #Configure

/* Retreve the comand shell setting */
INSERT  INTO #Configure
        (NAME
       , Min
       , Max
       , Config_Value
       , Run_value
        )
        EXEC sp_configure 'xp_cmdshell'

SELECT  @CmdShell = Config_Value
FROM    #Configure

/* Set to 1 if needed */
IF @CmdShell = 0 
    BEGIN
        EXEC sp_configure 'xp_cmdshell', 1
        RECONFIGURE
    END


DECLARE @SQL NVARCHAR(4000)
SET @SQL =  'copy ' + @RemoteBAKFileName + ' ' + @LocalBAKFileName
print @SQL
exec xp_cmdshell @SQL


create table #Temp (
LogicalName nvarchar(128)
,PhysicalName nvarchar(260)
,Type char(1)
,FileGroupName nvarchar(128)
,Size numeric(20,0)
,MaxSize numeric(20,0)
,FileID bigint
,CreateLSN numeric(25,0)
,DropLSN numeric(25,0) NULL
,UniqueID uniqueidentifier
,ReadOnlyLSN numeric(25,0) NULL
,ReadWriteLSN numeric(25,0) NULL
,BackupSizeInBytes bigint
,SourceBlockSize int
,FileGroupID int
,LogGroupGUID uniqueidentifier 
,DifferentialBaseLSN numeric(25,0) 
,DifferentialBaseGUID uniqueidentifier
,IsReadOnly bit
,IsPresent bit
,TDEThumbprint varbinary(32)
)

set @SQL = 'RESTORE filelistonly FROM DISK = ''' + @LocalBAKFileName + ''' WITH NOUNLOAD; '

insert into #Temp 
exec sp_executeSQL @SQL

--select * from #Temp
declare @CRLF char(2)
set @CRLF = CHAR(13) + CHAR(10)

Declare @DataName Varchar(255)
Declare @LogName varchar(255)
Declare @DataPhyName varchar(255)
Declare @LogPhyName varchar(255)

Select @DataName = LogicalName, @DataPhyName = PhysicalName from #Temp where Type = 'D'
Select @LogName = LogicalName, @LogPhyName = PhysicalName from #Temp where Type = 'L'

set @DataPhyName = right(@DataPhyName,charindex('\',reverse(@DataPhyName))-1)
set @LogPhyName = right(@LogPhyName,charindex('\',reverse(@LogPhyName))-1)

set @SQL = 'RESTORE DATABASE '+ @DBName +  @CRLF
set @SQL = @SQL + '  FROM Disk =''' + @LocalBAKFileName + '''' + @CRLF
set @SQL = @SQL + '   WITH RECOVERY, ' +  @CRLF
set @SQL = @SQL + '     MOVE ''' + @DataName + ''' TO ' +  @CRLF
set @SQL = @SQL + '      ''' + @DataFilePath + @DataPhyName + ''', ' +  @CRLF
set @SQL = @SQL + '     MOVE ''' + @LogName + ''' TO ' +  @CRLF
set @SQL = @SQL + '      ''' + @LogFilePath + @LogPhyName + '''' +  @CRLF

print @SQL
exec sp_executeSQL @SQL 



set @SQL = 'USE [master]' + @CRLF
set @SQL = @SQL + 'ALTER DATABASE [' + @DBName + '] SET COMPATIBILITY_LEVEL = ' + @COMPATIBILITY_LEVEL + @CRLF
if @SimpleMode = 1 
	set @SQL = @SQL + 'ALTER DATABASE [' + @DBName + '] SET RECOVERY SIMPLE WITH NO_WAIT' + @CRLF
	
print @SQL
exec sp_executeSQL @SQL 

drop table #Temp

set @SQL = 'del ' + @LocalBAKFileName
exec xp_cmdshell @SQL

/* Reset cmd shell setting if needed */
IF @CmdShell = 0 
    BEGIN
        EXEC sp_configure 'xp_cmdshell', 0
        RECONFIGURE
    END

/* Reset Advanced options if neede */
IF @AdvanceOptions = 0 
    BEGIN
        EXEC sp_configure 'show advanced options', 0
        RECONFIGURE
    END
    
DROP TABLE #Configure