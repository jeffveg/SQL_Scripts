USE [msdb]
GO

/****** Object:  Job [Test]    Script Date: 1/3/2020 3:25:30 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT,@jobid UNIQUEIDENTIFIER,@StartStepID INT
SELECT @ReturnCode = 0

SELECT @jobId = job_id FROM msdb.dbo.sysjobs WHERE name = 'SSIS_T16INS1643'


/* to do .... need to get the start ID because some of the jobs do not start with setp 1*/
SELECT @StartStepID =  j.start_step_id FROM msdb.dbo.sysjobs j WHERE j.job_id = @jobid

PRINT @StartStepID

/*increment becasue we are inserting a step */
SET  @StartStepID = @StartStepID +1 

/****** Object:  Step [Check if Primary]    Script Date: 1/3/2020 3:25:30 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check if Primary', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=@StartStepID, 
		@on_fail_action=1, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @AGName sysname, @RunIfPrimary bit;
set @AGName = null; -- if there is more than one AG on the server set the name AG name here
set @RunIfPrimary = ''TRUE'';
 
/* Below with check the role of the server and error depending on the setting above */
declare @Role int
select @Role = hars.role
from sys.dm_hadr_availability_replica_states as hars
    join sys.dm_hadr_name_id_map as map
        on hars.group_id = map.ag_id
    join sys.availability_replicas as ar
        on hars.replica_id = ar.replica_id
where hars.is_local = 1 and hars.operational_state = 2 and map.ag_name = isnull(@AGName, map.ag_name);
 
declare @MSG nvarchar(100);
if @Role = 1 and @RunIfPrimary = ''FALSE''
begin
    set @MSG = ''This the primary node for '' + isnull(@AGName, ''default'') + '' and RunIfPrimary is False.'';
    raiserror(@MSG, 16, 1);
end;
if @Role = 2 and @RunIfPrimary = ''TRUE''
begin
    set @MSG = ''This the primary node for '' + isnull(@AGName, ''default'') + '' and RunIfPrimary is True.'';
    raiserror(@MSG, 16, 1);
end;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


