/****** Object:  StoredProcedure [dbo].[sp_syn]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[sp_syn]
	@synname varchar(15),
	@target varchar(150)
as
declare @sql varchar(300)
select @sql = 'use ?; declare @db varchar(50); select @db = db_name(); if @db NOT IN (''ReportingTables'',''ReportTables'') begin drop synonym if exists ' + @synname + ' create synonym ' + @synname + ' for ' + @target + ' end'
exec sp_msforeachDb @sql
GO
