if exists( Select * from tempdb.dbo.sysobjects where name = N'##SP_Who')
	drop table ##SP_Who

create table ##SP_Who 
	(
	spid int,
	ecid int,
	status varchar(20),        
	loginame varchar(50),                                                                                                               
	hostname varchar(20),                                                                                                      
	blk int,
	dbname varchar(20),
	cmd varchar(200), 
	request_id int
	)
insert into ##SP_Who
exec sp_who 


select 
	spid, 
	status, 
	blk, 
	dbname, 
	cmd  
from 
	##SP_Who 
where 
	loginame = 'sa' 
-- kill 103