
DROP FUNCTION dbo.udf_Chameleon_Int;
GO
DROP FUNCTION dbo.udf_Chameleon_Numeric;

GO 



CREATE FUNCTION dbo.udf_Chameleon_Int (@Int AS BIGINT)
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

CREATE FUNCTION dbo.udf_Chameleon_Numeric (@Numeric AS NUMERIC(18,2))
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
PRINT dbo.udf_Chameleon_numeric(1000000.3655);
