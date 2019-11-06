USE [reports]
GO

/****** Object:  Table [dbo].[new_dialer_export]    Script Date: 02/14/2009 14:48:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[new_dialer_export]') AND type in (N'U'))
DROP TABLE [dbo].[new_dialer_export]
GO

USE [reports]
GO

/****** Object:  Table [dbo].[new_dialer_export]    Script Date: 02/14/2009 14:48:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[new_dialer_export](
	[recno] [int] IDENTITY(1,1) NOT NULL,
	[entrydate] [char](6) NULL,
	[memberid] [char](16) NULL,
	[contract] [char](10) NULL,
	[campaign] [char](10) NULL,
	[prospectid] [char](16) NULL,
	[name1] [char](25) NULL,
	[mainphone] [char](10) NULL,
	[name2] [char](25) NULL,
	[altphone] [char](10) NULL,
	[address] [char](30) NULL,
	[city] [char](20) NULL,
	[state] [char](2) NULL,
	[zip] [char](9) NULL,
	[email] [char](50) NULL,
	[last] [char](6) NULL,
	[cruiseline] [char](20) NULL,
	[lastdestination] [char](20) NULL,
	[cost] [char](5) NULL,
	[how] [char](3) NULL,
	[nextdestination] [char](20) NULL,
	[source] [char](50) NULL,
	[agent_sold] [char](10) NULL,
	[comments] [char](75) NULL,
 CONSTRAINT [PK_new_dialer_export] PRIMARY KEY CLUSTERED 
(
	[recno] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'date of sale. enrollment_date' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'entrydate'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'REQ. member.members.member_id' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'memberid'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'REQ. contract number. sharepoint task number' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'contract'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'OPT. campaign' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'campaign'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'OPT. prospect id' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'prospectid'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'REQ. primary name' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'name1'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'REQ. primary phone' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'mainphone'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'OPT. secondary name' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'name2'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'OPT. secondary phone' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'altphone'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'REQ. primary address' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'address'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'REQ. address city' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'city'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'REQ. address state abbrev' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'state'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'REQ. up to 9 digit post code' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'zip'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'REQ. email address' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'email'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'OPT. date YYMMDD of last cruise' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'last'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'OPT. cruise line' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'cruiseline'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'OPT. last destination of vacation' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'lastdestination'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'OPT. cost of last trip' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'cost'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'OPT. how was the trip booked' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'how'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'OPT. future trip interest' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'nextdestination'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'REQ. lead source or resort name' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'source'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'OPT. agent that sold the trip' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'agent_sold'
GO

EXEC sys.sp_addextendedproperty @name=N'Caption', @value=N'OPT. discretionary comments that will be viewable' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'new_dialer_export', @level2type=N'COLUMN',@level2name=N'comments'
GO


