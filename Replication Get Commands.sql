
USE distribution
GO

EXECUTE sp_browsereplcmds
@xact_seqno_start = '',
@xact_seqno_end = ''--,

 --  DELETE dbo.MSrepl_commands WHERE xact_seqno = 0x00299F030002770B000500000000 AND command_id = 1