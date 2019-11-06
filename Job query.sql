Use msdb
GO
select 
	job.name,
--	job.description,
	step.Step_id,
	step.step_name,
	last_run_date = 
		case when last_Run_date = 0
			then null
			else
				cast(
					  left( right( step.last_Run_date, 4), 2) -- Month
					+ '/'
					+ right( step.last_Run_date, 2) -- Day
					+ '/'
					+ left( step.last_Run_date, 4)  -- year
					+ ' '
					+ left( right( '000000' + cast( step.last_run_time as varchar(20)), 6 ), 2 )-- hours
					+ ':' 
					+ left( right( '000000' + cast( step.last_run_time as varchar(20)), 4), 2 ) --min
					+ ':'
					+ right (right( '000000' + cast( step.last_run_time as varchar(20)), 6), 2 ) -- sec
				as datetime )
			end,
	Step_last_run_duration=
		  left( right( '000000' + cast( step.last_run_duration as varchar(20)), 6 ), 2 )-- hours
		+ ':' 
		+ left( right( '000000' + cast( step.last_run_duration as varchar(20)), 4), 2 ) --min
		+ ':'
		+ right (right( '000000' + cast( step.last_run_duration as varchar(20)), 6), 2 ),
 	step.last_run_retries,
	hist.run_status,
	job.job_id
from 
	sysjobs job (READPAST)
	join sysjobsteps step (READPAST) on 
		step.job_id = job.job_id
	Left join sysjobhistory hist (READPAST) on 
		hist.job_id = job.job_id
		and hist.step_id = step.step_id 
		and hist.run_date = step.last_run_date
		and hist.run_time = step.last_run_time
order by 
	name,
	step.Step_id