/****** Object:  StoredProcedure [dbo].[sp_ChangeSAPassword]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[sp_ChangeSAPassword]
    (
	        @Password NVARCHAR(100)
    )
AS
    DECLARE
        @SQL NVARCHAR(200)
      , @UserName NVARCHAR(32);

    SELECT
        @UserName = name
    FROM
        master.sys.syslogins
    WHERE
        sid = 0X01;

    SET @SQL = 'ALTER LOGIN [' + @UserName + '] WITH PASSWORD = ''' + @Password + '''';

    EXEC sys.sp_executesql
        @SQL;

    SELECT 
        @UserName AS SA_Name;
GO
