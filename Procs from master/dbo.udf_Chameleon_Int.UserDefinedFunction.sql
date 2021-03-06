/****** Object:  UserDefinedFunction [dbo].[udf_Chameleon_Int]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_Chameleon_Int] (@Int AS BIGINT)
RETURNS VARCHAR(255)
AS
BEGIN

    DECLARE @Ret VARCHAR(255);

    IF @Int IS NULL
        SET @Ret = NULL;


    ELSE
        BEGIN

            SET @Ret = CONVERT(VARCHAR(255), CAST(@Int AS MONEY), 101);
            SET @Ret = LEFT(@Ret, LEN(@Ret) - 3);
        END;

    RETURN @Ret;
END;

GO
