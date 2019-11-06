/****** Object:  StoredProcedure [dbo].[usp_DBA_TempDB_TrackUsage]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_DBA_TempDB_TrackUsage]
AS
SET NOCOUNT ON;
DECLARE @collectiondate DATETIME
SET @collectiondate = GETDATE()

EXEC [dbo].[usp_DBA_TempDB_TrackTDriveSize]
EXEC [dbo].[usp_DBA_TempDB_TrackSessions]

GO
