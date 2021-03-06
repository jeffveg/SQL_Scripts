/****** Object:  UserDefinedFunction [dbo].[udf_Chameleon_Numeric]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[udf_Chameleon_Numeric] (@Numeric AS NUMERIC(18,2))
RETURNS VARCHAR(255)
AS
BEGIN

    DECLARE @Ret VARCHAR(255);

    IF @Numeric IS NULL
        SET @Ret = NULL;
    ELSE
        SET @Ret = CONVERT(VARCHAR(255), CAST(@Numeric AS MONEY), 101);
    RETURN @Ret;
END;

GO
