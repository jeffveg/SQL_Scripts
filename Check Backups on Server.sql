DECLARE @Default_Full_Days int, @Default_Log_Hours int, @SQL NVARCHAR(4000)

SET @Default_Full_Days = 1
SET @Default_Log_Hours = 2

CREATE TABLE #BackupExecptions (
	 Server_Name VARCHAR(255)
	,Database_Name VARCHAR(255)
	,Full_Backup_Days INT
	,Log_Backup_Hours INT
	,Do_Not_Backup INT
	,Ignore_Offline INT
	,Notes VARCHAR(1000)
	)
/* Database exceptions */
/* Monthy Backups */
INSERT INTO #BackupExecptions values ('SGSHAREDSQL2\PROD2008','RECMAN_Table',31,NULL,NULL,NULL,'Monthy Backups')
INSERT INTO #BackupExecptions values ('OHCOLDBP0093\SGAIR2008','AddressServer_Tiger',31,NULL,NULL,NULL,'Monthy Backups')
INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','Poll_J_Workspace',31,NULL,NULL,NULL,'Monthy Backups')
INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','SMITHW4_Workspace',36,NULL,NULL,NULL,'First sunday of the month')
INSERT INTO #BackupExecptions values ('SASSQLPRODV2\PROD2008','Prem_A',31,NULL,NULL,NULL,'Monthy Backups')
INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AirAreaCode',31,NULL,NULL,NULL,'Monthy Backups')
INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AirCl2Ind',31,NULL,NULL,NULL,'Monthy Backups')
INSERT INTO #BackupExecptions values ('SICSHAREDSQL1\PROD2000','DICT_BRK',31,NULL,NULL,NULL,'Monthy Backups')
INSERT INTO #BackupExecptions values ('SICSHAREDSQL1\PROD2000','DICT_CAS',31,NULL,NULL,NULL,'Monthy Backups')
INSERT INTO #BackupExecptions values ('SICSHAREDSQL1\PROD2000','DICT_PERS',31,NULL,NULL,NULL,'Monthy Backups')
INSERT INTO #BackupExecptions values ('SICSHAREDSQL1\PROD2000','DICT_PROP',31,NULL,NULL,NULL,'Monthy Backups')
INSERT INTO #BackupExecptions values ('SICSHAREDSQL1\PROD2000','DICT_TRANS',31,NULL,NULL,NULL,'Monthy Backups')
INSERT INTO #BackupExecptions values ('SICSHAREDSQL1\PROD2000','LOADP000',31,NULL,NULL,NULL,'Monthy Backups')
INSERT INTO #BackupExecptions values ('SGAZSQL08\PROD2008','WIN-PAK Archive',31,NULL,NULL,NULL,'Monthy Backups')

/* Weekly Backups*/
INSERT INTO #BackupExecptions values ('SGSHAREDSQL2\PROD2008','CIPS_INTERFACES_TELMA',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AddressServer_Tiger',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AirCL2Exp_Actuarial_2013Q2',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AirCL2Exp_Actuarial_2013Q3',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AirCL2Exp_Actuarial_2013Q3_v14',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AirCL2Exp_Actuarial_2013Q4',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AirCL2Loss_Actuarial_2013Q2',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AirCL2Loss_Actuarial_2013Q3',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AirCL2Loss_Actuarial_2013Q3_v14',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AirCL2Loss_Actuarial_2013Q4',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('SGRTI\RTI2008','custWHIC',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('SGRTI\RTI2008','custWHIC_dw',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('SGRTI\RTI2008','master',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('SGRTI\RTI2008','model',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('SGRTI\RTI2008','msdb',7,NULL,NULL,NULL,'Weekly Backups')
INSERT INTO #BackupExecptions values ('SGRTI\RTI2008','SQLEvents',7,NULL,NULL,NULL,'Weekly Backups')

/* Other */
INSERT INTO #BackupExecptions values ('PANSY','VMAEDM',NULL,1000000,NULL,NULL,'No longer in Full')
INSERT INTO #BackupExecptions values ('SICSHAREDSQL1\PROD2000','ADJADV',NULL,1000000,NULL,NULL,'No longer in Full')
INSERT INTO #BackupExecptions values ('SGSIRISDB\SIRIS2008','SharePoint_AdminContent_3166c4e1-5777-4366-8e02-385fd4a510ae',NULL,25,NULL,NULL,'Log backup once a day')
INSERT INTO #BackupExecptions values ('SGSIRISDB\SIRIS2008','SharePoint_StateServiceDB',NULL,25,NULL,NULL,'Log backup once a day')
INSERT INTO #BackupExecptions values ('SGSIRISDB\SIRIS2008','Secure_Store_Service_DB',NULL,25,NULL,NULL,'Log backup once a day')
INSERT INTO #BackupExecptions values ('SGSIRISDB\SIRIS2008','WordAutomationServices',NULL,25,NULL,NULL,'Log backup once a day')
INSERT INTO #BackupExecptions values ('SGSIRISDB\SIRIS2008','SharePoint_Config',NULL,25,NULL,NULL,'Log backup once a day')
INSERT INTO #BackupExecptions values ('SGSIRISDB\SIRIS2008','WSS_Content',NULL,25,NULL,NULL,'Log backup once a day')
 
/*Retiring Server Ignore */ 
INSERT INTO #BackupExecptions values ('PANSY','ServerToRetire',NULL,NULL,NULL,NULL,'Server scheduled to retire')
INSERT INTO #BackupExecptions values ('MARIGOLD','ServerToRetire',NULL,NULL,NULL,NULL,'Server scheduled to retire')
INSERT INTO #BackupExecptions values ('OHLEWDBP0123\DBAADMIN','ServerToRetire',NULL,NULL,NULL,NULL,'Server scheduled to retire')
INSERT INTO #BackupExecptions values ('OHLEWDBP0123\DTSADMIN','ServerToRetire',NULL,NULL,NULL,NULL,'Server scheduled to retire')
INSERT INTO #BackupExecptions values ('AZSCOAPP0017','ServerToRetire',NULL,NULL,NULL,NULL,'Server scheduled to retire')


/* Dev Servers */
INSERT INTO #BackupExecptions values ('OHCOLDBD0040\DEV2000','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('GLENWOOD_LM2','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('VMONTREAL','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('OHCOLDBD0041\SQA2000','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('AZSCODBD0001\DEV2005','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('VLIHUETST','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('VAKRON\DEV2005','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('OHCOLDBD0040\DEV2005','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('OHCOLDBD0041\SQA2005','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('SGSHAREDSQL1T\SQA2005','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('AZSCODBD0001\DEV2008','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('OHNALDBD0020\DEV2005','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('OHNALDBD0020\DEV2008','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('OHCOLDBD0040\DEV2008','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('OHCOLDBP0057\SQA2008','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('OHCOLDBP0092\PTADMIN','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('SEAHAWK','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('OHCOLDBD0041\SQA2008','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('SGRTIT\SQARTI2008','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('SGSHAREDSQL2T\SQA2008','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('OHNALDBD0021\SQAAIR2008','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('SGSIRISDBT\SQASIRIS2008','DevServer',NULL,NULL,NULL,NULL,'Dev Server')
INSERT INTO #BackupExecptions values ('OHCOLDBP0092\DBAADMIN','DevServer',NULL,NULL,NULL,NULL,'Dev Server')


/* Not important to backup */
INSERT INTO #BackupExecptions values ('LIHUE','AIE',NULL,NULL,1,NULL,'Backups stoped over a year ago')
INSERT INTO #BackupExecptions values ('SGAZSQL01\SQL2000','Northwind',NULL,NULL,1,NULL,'SQL example database')
INSERT INTO #BackupExecptions values ('SGAZSQL01\SQL2000','pubs',NULL,NULL,1,NULL,'SQL example database')


/* Dont Run on the weekend */
if datepart(Weekday,getdate()) in (1,2,7) 
Begin
	INSERT INTO #BackupExecptions values ('SGAZSQL01\SQL2000','TRACKERPROD',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AirCL2Exp',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AirCL2Loss',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AirCommon',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AIRExpWork',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AirJob',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AIRLicence',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AIRProfiler',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','AIRReport',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','CatstationV3',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','SG_Actuarial_Reports',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('OHLEWDBP0204\SGAIR2008','WebCommon',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('SGSHAREDSQL2\PROD2008','FINRPT',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('SGSHAREDSQL2\PROD2008','KOFAXGRASP',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('SICSHAREDSQL1\PROD2000','APLUSINFO',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('SICSHAREDSQL1\PROD2000','CATS_WINS_Upload',3,NULL,NULL,NULL,'Backup does not run on weekends')
	INSERT INTO #BackupExecptions values ('SICSHAREDSQL1\PROD2000','SPDPERFORM',3,NULL,NULL,NULL,'Backup does not run on weekends')
end

CREATE TABLE #DatabaseStatus (
	 Server_Name VARCHAR(255)
	,Database_Name VARCHAR(255)
	,Compatibility_Level VARCHAR(4)
	,Backup_Date DATETIME
	,Backup_Type CHAR(1)
	,Database_Status INT
	,Recovery_Model VARCHAR(100)
	,Capture_Date DATETIME
)

IF LEFT(CONVERT(VARCHAR(20),ServerProperty('ProductVersion')),1) = '8'
BEGIN
/* SQL 2000 Missing Recovery Model and is_copy_only */
SET @SQL = 
	'SELECT 
		 CAST(ServerProperty(''servername'')AS VARCHAR(30)) Server_Name
		,d.name Database_Name
		,d.cmptlevel
		,b.Backup_Date
		,b.Type
		,d.Status
		,''SIMPLE'' /* recovery_model */
		,GETDATE()
	FROM 
		master..sysdatabases d 
		LEFT JOIN (
			SELECT 
				 Database_Name
				,MAX(backup_finish_date) Backup_Date
				,Type
			FROM 
				msdb..backupset 
			GROUP BY 
				 Database_Name
				,Type) b 
				ON d.name = b.database_name
		LEFT JOIN msdb..backupset x 
			ON  x.Database_Name = b.database_name
				AND x.backup_finish_date = b.Backup_Date
				AND x.type = b.type'
END
ELSE
BEGIN
SET @SQL = 
	'SELECT 
		 CAST(ServerProperty(''servername'')AS VARCHAR(30)) Server_Name
		,d.name Database_Name
		,d.cmptlevel
		,b.Backup_Date
		,b.Type
		,d.Status
		,recovery_model
		,GETDATE()
	FROM 
		master..sysdatabases d 
		LEFT JOIN (
			SELECT 
				 Database_Name
				,MAX(backup_finish_date) Backup_Date
				,Type
			FROM 
				msdb..backupset 
			WHERE 
				is_copy_only = 0 	
			GROUP BY 
				 Database_Name
				,Type) b 
				ON d.name = b.database_name
		LEFT JOIN msdb..backupset x 
			ON  x.Database_Name = b.database_name
				AND x.backup_finish_date = b.Backup_Date
				AND x.type = b.type'

END


Insert INTO #DatabaseStatus
EXEC sp_executeSQL @SQL


/* Remove backups of read-only db's less then one month old */
DELETE #DatabaseStatus 
WHERE 
		DATEDIFF(DAY,Backup_Date,Capture_Date) < 31
		AND Database_Status & 1024 = 1024
			
/* Remove log backups of read-only db's */			
DELETE #DatabaseStatus 
WHERE 
		Backup_Type = 'L'
		AND Database_Status & 1024 = 1024 			

DELETE #DatabaseStatus 
WHERE 
	Server_Name in (
					SELECT Server_Name 
					FROM #BackupExecptions 
					WHERE Database_Name = 'ServerToRetire'
					)


DELETE #DatabaseStatus 
WHERE 
	Server_Name in (
					SELECT Server_Name 
					FROM #BackupExecptions 
					WHERE Database_Name = 'DevServer'
					)


/* Old Full Backups */
SELECT  
	 s.Server_Name
	,s.Database_Name
	,CASE DATEDIFF(DAY,s.Backup_Date,s.Capture_Date)
		WHEN 1 
			THEN CAST(DATEDIFF(DAY,s.Backup_Date,s.Capture_Date) AS VARCHAR(4)) + ' Day since last FULL backup'
		ELSE 
			CAST(DATEDIFF(DAY,s.Backup_Date,s.Capture_Date) AS VARCHAR(4)) + ' Days since last FULL backup' 
		END Database_Issue
		,s.Database_Status & 1024 DatabaseIsReadOnly
FROM 
	#DatabaseStatus s
	LEFT JOIN #BackupExecptions e
		ON  s.Server_Name = e.Server_Name
			AND s.Database_Name = e.Database_Name
WHERE 
	DATEDIFF(DAY,s.Backup_Date,s.Capture_Date) > COALESCE(e.Full_Backup_Days,@Default_Full_Days)
	AND Backup_Type NOT IN ('L','I') /* I is incremintal If this is used I will need to change this */
	AND COALESCE(e.Do_Not_Backup,0) = 0
	AND NOT s.Database_Status & 512 = 512 /* IF DB is OFFLINE we can't see the backup status */

UNION

/* Old Log Backups */
SELECT  
	 s.server_Name
	,s.Database_Name
	,CASE DATEDIFF(DAY,s.Backup_Date,s.Capture_Date)
		WHEN 1 
			THEN CAST(DATEDIFF(HOUR,s.Backup_Date,s.Capture_Date) AS VARCHAR(10)) + ' Hour since last LOG backup'
		ELSE 
			CAST(DATEDIFF(HOUR,s.Backup_Date,s.Capture_Date) AS VARCHAR(10)) + ' Hours since last LOG backup' 
		END Database_Issue
	,s.Database_Status & 1024 
FROM 
	#DatabaseStatus s
	LEFT JOIN #BackupExecptions e
		ON  s.Server_Name = e.Server_Name
			AND s.Database_Name = e.Database_Name
WHERE 
	DATEDIFF(HOUR,s.Backup_Date,s.Capture_Date) > COALESCE(e.Log_Backup_Hours,@Default_Log_Hours)
	AND Backup_Type = 'L'
	AND COALESCE(e.Do_Not_Backup,0) = 0
	AND NOT s.Database_Status & 512 = 512 /* IF DB is OFFLINE we can't see the backup status */
	
UNION
/* Missing Full Backups*/
SELECT  
	 s.server_Name
	,s.Database_Name
	,'Database has not been backed up' Backup_Issues
	,s.Database_Status & 1024
FROM 
	#DatabaseStatus s
	LEFT JOIN #BackupExecptions e
		ON  s.Server_Name = e.Server_Name
			AND s.Database_Name = e.Database_Name
WHERE 
	Backup_Date IS NULL
	AND COALESCE(e.Do_Not_Backup,0) = 0
	AND s.Database_Name not in ('TEMPDB')
	AND NOT s.Database_Status & 512 = 512 /* IF DB is OFFLINE we can't see the backup status */

UNION
/* Missing Log Backups*/

SELECT  
	 l.server_Name
	,l.Database_Name
	,'Database not in SIMPLE and no LOG backups'
	,s.Database_Status & 1024
FROM (	
	SELECT  
		 s.server_Name
		,s.Database_Name
		,Backup_Type
	FROM 
		#DatabaseStatus s
	WHERE 
		s.Recovery_Model NOT IN ('SIMPLE')
		AND Backup_Type NOT IN ('L')
	) l
	LEFT JOIN #DatabaseStatus s
		ON	s.Server_Name = l.Server_Name
			AND s.Database_Name = l.Database_Name
			AND s.Backup_Type = 'L'
WHERE 
	s.Database_Name IS NULL
	AND l.Database_Name NOT IN ('MODEL')	
	AND NOT s.Database_Status & 512 = 512 /* IF DB is OFFLINE we can't see the backup status */


UNION
/* Other Database Issues */
SELECT  
	 s.server_Name
	,s.Database_Name
	,CASE 
		WHEN s.Database_Status & 256 = 256 
			THEN 'Database is Suspect'
		WHEN s.Database_Status & 128 = 128
			THEN 'Database is recovering' 
		WHEN s.Database_Status & 512 = 512
			THEN 'Database is offline'
		WHEN s.Database_Status & 32768 = 32768
			THEN 'Database is in emergency_mode'
		WHEN s.Database_Status & 4194304 = 4194304
			THEN 'Autoshrink is set on'
		ELSE NULL
	END Database_Issue
	,s.Database_Status & 1024
FROM 
	#DatabaseStatus s
	LEFT JOIN #BackupExecptions e
		ON  s.Server_Name = e.Server_Name
			AND s.Database_Name = e.Database_Name
WHERE
	s.Database_Status & 256 = 256 
	OR s.Database_Status & 128 = 128
	/* Ignore Offline for now
	OR 
		(s.Database_Status & 512 = 512
		 AND COALESCE(e.Ignore_Offline,0) = 0
		 ) */
	OR s.Database_Status & 32768 = 32768
	
	
ORDER by 1,2,3

DROP TABLE #DatabaseStatus
DROP TABLE #BackupExecptions

