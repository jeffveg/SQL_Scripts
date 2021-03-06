/****** Object:  StoredProcedure [dbo].[sp_who3]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE [dbo].[sp_who3]    
(    
 @filter tinyint = 1,    
 @filterspid int = NULL    
)    
AS    
SET NOCOUNT ON;    
    
DECLARE @processes TABLE    
  (    
  spid int,    
  blocked int,    
  databasename varchar(256),    
  hostname varchar(256),    
  program_name varchar(256),    
  loginame varchar(256),    
  status varchar(60),    
  cmd varchar(128),    
  cpu int,    
  physical_io int,    
  [memusage] int,    
  login_time datetime,    
  last_batch datetime,    
  current_statement_parent xml,
  current_statement_sub xml)

INSERT INTO @processes    
SELECT   sub.*
FROM
(
SELECT sp.spid,    
  sp.blocked,    
  sd.name,    
  RTRIM(sp.hostname) AS hostname, 
  RTRIM(sp.[program_name]) AS [program_name],    
  RTRIM(sp.loginame) AS loginame,    
  RTRIM(sp.status) AS status,    
  sp.cmd,    
  sp.cpu,    
  sp.physical_io,    
  sp.memusage,    
  sp.login_time,    
  sp.last_batch,
  (
    SELECT 
      LTRIM(st.text) AS [text()]
    FOR XML PATH(''), TYPE
   ) AS parent_text,  
  (
    SELECT 
      LTRIM(CASE
         WHEN LEN(COALESCE(st.text, '')) = 0 THEN NULL
         ELSE SUBSTRING(st.text, (er.statement_start_offset/2)+1, 
               ((CASE er.statement_end_offset
                  WHEN -1 THEN DATALENGTH(st.text)
                  ELSE er.statement_end_offset
                  END - er.statement_start_offset)/2) + 1)  
         END) AS [text()]
   FROM sys.dm_exec_requests er CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS st
   WHERE er.session_id = sp.spid
    FOR XML PATH(''), TYPE
   ) AS child_text
FROM  sys.sysprocesses sp WITH (NOLOCK) LEFT JOIN sys.sysdatabases sd WITH (NOLOCK) ON sp.dbid = sd.dbid
      CROSS APPLY sys.dm_exec_sql_text(sp.sql_handle) AS st
) sub INNER JOIN sys.sysprocesses sp2 ON sub.spid = sp2.spid
ORDER BY
   sub.spid

-- if specific spid required    
IF @filterspid IS NOT NULL    
 DELETE @processes    
 WHERE spid <> @filterspid    
    
-- remove system processes    
IF @filter = 1 OR @filter = 2    
 DELETE @processes    
 WHERE spid < 51
      OR spid = @@SPID 
    
-- remove inactive processes    
IF @filter = 2    
 DELETE  @processes    
 WHERE status = 'sleeping'    
   AND cmd IN ('AWAITING COMMAND')    
   AND blocked = 0    

SELECT spid,    
  blocked,    
  databasename,    
  hostname,    
  loginame,    
  status,    
  current_statement_parent,
  current_statement_sub,
  cmd,    
  cpu,    
  physical_io,    
  program_name,    
  login_time,    
  last_batch    
FROM @processes    
ORDER BY loginame

RETURN 0;    
GO
