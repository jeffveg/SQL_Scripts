
if exists( Select * from tempdb.dbo.sysobjects where name = N'##Tablespwho')
	drop table ##Tablespwho



CREATE TABLE ##Tablespwho(
        SPID INT,
        Status VARCHAR(8000),
        LOGIN VARCHAR(8000),
        HostName VARCHAR(8000),
        BlkBy VARCHAR(8000),
        DBName VARCHAR(8000),
        Command VARCHAR(8000),
        CPUTime INT,
        DiskIO INT,
        LastBatch VARCHAR(8000),
        ProgramName VARCHAR(8000),
        SPID_1 INT,
        REQUESTID int
)

INSERT INTO ##Tablespwho EXEC sp_who2

SELECT  *
FROM    ##Tablespwho
WHERE Status NOT IN ( 'sleeping','BACKGROUND                    ')