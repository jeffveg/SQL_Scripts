--use neo_prod
--go
--drop schema if exists cdc;
--go
--alter authorization on role::CDC_Reader to dbo
--go
--drop user if exists cdc
--go
--EXEC sys.sp_cdc_enable_db
--GO
--alter authorization on role::CDC_Reader to cdc
--go


--Create Filegroup for CDC if one doesn't exist
IF NOT EXISTS(SELECT * FROM sys.data_spaces WHERE [Name] = 'Revflow_CDC') BEGIN
	ALTER DATABASE neo_prod ADD FILEGROUP Revflow_CDC
	ALTER DATABASE neo_prod ADD FILE (NAME = Revflow_CDC,
									  FILENAME = 'E:\MSSQL\Data\Revflow_CDC_Restore.mdf',
									  SIZE = 1024MB,
									  FILEGROWTH = 512MB) TO FILEGROUP Revflow_CDC
									
END

--Create Work Table

/* this code creates the statments below run with results as file  */


/* this will get the list of tables in an existing db 
SELECT ',''' + name + ''''
FROM sys.tables
where is_tracked_by_cdc = 1
order by name
*/

DROP TABLE IF EXISTS #Work
CREATE TABLE #Work (ID INT IDENTITY(1,1), SQLText VARCHAR(MAX))

insert INTO #Work
SELECT 'IF NOT EXISTS(SELECT 1 FROM sys.tables t INNER JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.is_tracked_by_cdc = 1 AND t.[Name] = ''' + [Table_Name] + ''') BEGIN ' + 
'EXEC sys.sp_cdc_enable_table @source_schema = N''dbo'', @source_name = N''' + [Table_Name] + ''', @role_name = N''CDC_Reader'', @filegroup_name = N''Revflow_CDC'', @supports_net_changes = 1 END' 
FROM INFORMATION_SCHEMA.TABLES
WHERE [Table_Name] IN (
'A_COMPANY'
,'A_COMPANY_EMPLOYEE'
,'A_PROVIDER_SPECIALTY'
,'A_PROVIDER_TYPE'
,'A_ROLE'
,'A_USER'
,'A_USER_COMPANY'
,'A_USER_TYPE'
,'C_ADJUSTMENT_CODE'
,'C_DIAGNOSIS_CODE'
,'C_INSURANCE_CLASS'
,'C_INSURANCE_CODE'
,'C_INSURANCE_TYPE'
,'c_payer'
,'c_payer_detail'
,'c_payer_group'
,'c_payer_ins'
,'C_PAYMENT_CODE'
,'C_PLACE_OF_SERVICE'
,'C_PRACTICE'
,'C_PROCEDURE_CODE'
,'C_PROVIDER'
,'C_USER_POS'
,'D_CASE'
,'D_CHARGE'
,'D_CHARGE_HISTORY'
,'D_CLAIM'
,'D_MONTHEND_SUMMARY'
,'D_NOTE_CODE'
,'D_PATIENT'
,'D_PATIENT_CREDIT'
,'D_PATIENT_NOTE'
,'D_PATIENT_STATEMENT'
,'D_PAYMENT_ADJUSTMENT'
,'D_VISIT'
)

DECLARE @CurrentID INT = 1,
		@SQL VARCHAR(MAX)

WHILE @CurrentID IS NOT NULL BEGIN

	SET @SQL = (SELECT SQLText FROM #Work WHERE ID = @CurrentID)
	EXEC(@SQL)
	--select @SQL

	SET @CurrentID = (SELECT MIN(ID) FROM #Work WHERE ID > @CurrentID)
END
