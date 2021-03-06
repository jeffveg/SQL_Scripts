USE [DBADB]
GO
/****** Object:  StoredProcedure [dbo].[usp_Check_DB_Backup_Status_All_Servers]    Script Date: 08/16/2011 15:48:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_Check_DB_Backup_Status_All_Servers] 
    (
    @ReportDevError BIT = 'False'
    )
AS 
SET NOCOUNT ON

DECLARE @SQL NVARCHAR(4000)
DECLARE @CurSvr VARCHAR(100)
DECLARE @SrvVer INT
DECLARE @DrP CHAR(3)

DECLARE @Backups TABLE
    (
     DevOrProd NVARCHAR(10)
   , ServerName NVARCHAR(100)
   , DatabaseName NVARCHAR(128)
   , Backup_Finish_Date DATETIME
    ) 

DECLARE @Trans_Backups TABLE
    (
     DevOrProd NVARCHAR(10)
   , ServerName NVARCHAR(100)
   , DatabaseName NVARCHAR(128)
   , Trans_Backup_Finish_Date DATETIME
    ) 


DECLARE c1 CURSOR FAST_FORWARD READ_ONLY
FOR
SELECT  ServerName
      , Version
      , Dominion
FROM    Servers
ORDER BY 1

OPEN c1

FETCH NEXT FROM c1 INTO @cursvr, @SrvVer, @DrP

WHILE @@FETCH_STATUS = 0 
    BEGIN


        SET @SQL = 'Select ''' + @DrP + ''',''' + @CurSvr
            + ''', d.name,b.backup_finish_date as backup_finish_date  from '
            + @CurSvr + '.master.dbo.sysdatabases d
				left join (select * from ' + @CurSvr
            + '.msdb.dbo.backupset bi where type <> ''L'' and backup_start_date = ( select max(backup_start_date) from '
            + @CurSvr
            + '.msdb.dbo.backupset z where z.database_name = bi.database_name AND type <> ''L'')) b on
				b.database_name = d.name'

        --PRINT @Sql
        INSERT  INTO @Backups
                EXEC sp_executesql @Sql
               
               
        SET @SQL = 'Select ''' + @DrP + ''',''' + @CurSvr
            + ''', d.name, b.backup_finish_date trans_backup_finish_date  from '
            + @CurSvr + '.master.dbo.sysdatabases d
				left join (select * from ' + @CurSvr
            + '.msdb.dbo.backupset bi where type = ''L'' and backup_start_date = ( select max(backup_start_date) from '
            + @CurSvr
            + '.msdb.dbo.backupset z where z.database_name = bi.database_name and type = ''L'')) b on
				b.database_name = d.name
				WHERE status & 8 <>  8'
               
        --PRINT @Sql
        INSERT  INTO @Trans_Backups
                EXEC sp_executesql @Sql
        FETCH NEXT FROM c1 INTO @cursvr, @SrvVer, @DrP
    END

CLOSE c1
DEALLOCATE c1



SELECT  b.DevOrProd
      , b.ServerName
      , b.DatabaseName
      , CAST(CASE WHEN b.DevOrProd = 'DEV'
                  AND @ReportDevError = 'False' THEN NULL
             WHEN Backup_Finish_Date IS NULL AND b.DatabaseName <> 'tempdb'
			 THEN 'This Database has never been backed up!'
             WHEN Backup_Finish_Date < GETDATE() - 7
             THEN 'Last Backup over a Week Old!'
             WHEN t.DatabaseName IS NOT NULL
                  AND Trans_Backup_Finish_Date IS NULL
                  AND b.DatabaseName <> 'model'
             THEN 'Recovery is Full and no Transaction Log Backups!'
             WHEN Trans_Backup_Finish_Date < GETDATE() - 1 
				  AND b.DatabaseName <> 'model'
             THEN 'Last Transaction Log Backup is over a Day old!'
        END AS NVARCHAR(100)) AS BackupIssues
      , b.Backup_Finish_Date
      , CAST(CASE WHEN t.DatabaseName IS NULL THEN 'Simple'
             ELSE 'Full'
        END AS NVARCHAR(10)) AS DBRecoveryMode
      , t.Trans_Backup_Finish_Date
FROM    @Backups b
        LEFT JOIN @Trans_Backups t
            ON b.DevOrProd = t.DevOrProd
               AND b.ServerName = t.ServerName
               AND b.DatabaseName = t.DatabaseName
ORDER BY CASE WHEN b.DevOrProd = 'DEV' THEN 'ZZZZZ' ELSE b.DevOrProd END 
      , ServerName
      , DatabaseName

