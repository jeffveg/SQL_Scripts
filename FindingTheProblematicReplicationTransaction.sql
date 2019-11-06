Use distribution;

Declare @PublisherDB sysname,
      @PublisherDBID int,
      @SeqNo nchar(22),
      @CommandID int

-- Set publisher database name and values from Replication Monitor
Set @PublisherDB = N'content'
Set @SeqNo = N'0x001E676400015214003800000000'
Set @CommandID = 12
 
-- Find the publisher database ID
Select @PublisherDBID = id
From dbo.MSpublisher_databases
Where publisher_db = @PublisherDB
 
-- Get the command
Exec sp_browsereplcmds
      @xact_seqno_start = @SeqNo,
      @xact_seqno_end = @SeqNo,
      @command_id = @CommandID,
      @publisher_database_id=@PublisherDBID;

-- {CALL [dbo].[sp_MSins_dboports_of_call_codes] (929,'LOP')}
-- select * from content..ports_of_call_codes where portofcallrecno = 929

