use neo_prod
go
drop schema if exists cdc;
go
alter authorization on role::CDC_Reader to dbo
go
drop user if exists cdc
go
EXEC sys.sp_cdc_enable_db
GO
alter authorization on role::CDC_Reader to cdc
go


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
EXEC sys.sp_cdc_enable_db  

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
,'A_PEND_REASON'
,'A_provider_qualifier'
,'A_PROVIDER_SPECIALTY'
,'A_PROVIDER_TYPE'
,'A_ROLE'
,'a_specialty_mod_ins_class'
,'a_specialty_mod_payer'
,'A_STATUS_CODE'
,'A_USER'
,'A_USER_COMPANY'
,'A_USER_TYPE'
,'C_ADJUSTMENT_CODE'
,'C_ALT_FEE_SCHEDULE'
,'C_ALT_PROVIDER'
,'C_DIAGNOSIS_CODE'
,'C_INSURANCE_CLASS'
,'C_INSURANCE_CODE'
,'C_INSURANCE_TYPE'
,'C_Medical_Group'
,'c_payer'
,'c_payer_detail'
,'c_payer_group'
,'c_payer_ins'
,'C_PAYMENT_CODE'
,'C_PLACE_OF_SERVICE'
,'c_pqrs_meas_modifier'
,'c_pqrs_meas_proc_code_qual'
,'c_pqrs_meas_proc_code_rptg'
,'C_PRAC_PROC'
,'C_PRACTICE'
,'C_PROCEDURE_CODE'
,'C_PROCEDURE_MODIFIER'
,'C_PROVIDER'
,'c_provider_pos'
,'C_REFERRING_PHYSICIAN'
,'C_REFERRING_SOURCE'
,'C_REFERRING_SOURCE_TYPE'
,'C_REVENUE_CENTER'
,'d_appt'
,'D_CASE'
,'D_CHARGE'
,'D_CLAIM'
,'d_claim_hdr'
,'d_claim_hdr_status'
,'D_ME_Aging_Detail'
,'D_ME_Aging_Detail_bycurins'
,'D_ME_AssociatedPaymentsByDOS'
,'D_ME_CHARGE'
,'d_me_patient_credit_bycurins'
,'D_ME_PAYMENT_ADJUSTMENT'
,'D_MONTHEND_INVOICE'
,'D_MONTHEND_INVOICE_LINE'
,'D_MONTHEND_SUMMARY'
,'D_NOTE_CODE'
,'D_PATIENT'
,'D_PATIENT_CREDIT'
,'D_PATIENT_NOTE'
,'D_PATIENT_STATEMENT'
,'D_PAYMENT_ADJUSTMENT'
,'D_SUBSCRIBER'
,'d_subscriber_doctors_orders'
,'d_subscriber_eligibility'
,'D_SUBSCRIBER_PREAUTH'
,'D_VISIT'
,'e277_status_cat'
,'e277_status_cd'
,'e277_status_cd_grp'
,'EOB_ClaimAdjCode'
,'EOB_LINE_ITEM'
,'EOB_PAYER_RULE'
,'EOB_RELEASE'
,'Eob_Release_Line_Item'
,'fmt_run'
,'fmt_run_comp'
/* Added 08/12/2020 JKS*/
,'D_SUBSCRIBER_PREAUTH'  
,'A_PATIENT_CREDIT_TYPE'  
,'A_PAYMENT_TYPE'  
,'AdjQualifier'
,'C_REFERRING_PHYSICIAN'
,'Eob_prvAdjCode'
,'EOB_provAdjustment'
,'eob_Moa'
,'Eob_HRCCode'
,'eob_hrc_code'
,'Eob_AdjQualifier'
,'C_Provider_Map'
,'C_Proc_Code_Map'
,'a_webpt_ins_type'
)

DECLARE @CurrentID INT = 1,
		@SQL VARCHAR(MAX)

WHILE @CurrentID IS NOT NULL BEGIN

	SET @SQL = (SELECT SQLText FROM #Work WHERE ID = @CurrentID)
	EXEC(@SQL)
	--select @SQL

	SET @CurrentID = (SELECT MIN(ID) FROM #Work WHERE ID > @CurrentID)
END
		
		
		
		
		--EXEC sys.sp_cdc_add_job @job_type = 'capture';  
  --  		EXEC sys.sp_cdc_add_job @job_type = 'cleanup';  