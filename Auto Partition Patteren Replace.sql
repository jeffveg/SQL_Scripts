ALTER FUNCTION PartitionCreate.usp_ReplacePatternStringForPartitions
    (
      @PatternString NVARCHAR(2000) ,
      @ReferenceDate DATE
    )
RETURNS NVARCHAR(2000)
AS
    BEGIN

/********************************************************************************
* Pattern Recognition															*
* The replace part of the pattern will be enclosed in curly brackets { }		*
* There can be multiple replace patterns i.e.  abc_{Q}_{+1} => abc_Q1_Q2		*
* W = Week number																*
* D = Day Number																*
* M = Month Number																*
* Y = last 2 digits of Year														*
* C = Century i.e. {CY} 2015													*
* Q = Quarter Number															*
* +N = Base Plus N i.e. {Y+1Y} for 2015 would be 1516							*
* Known Issues:																	*
*	If you put a not replaceable char in between brackets it will be a blank	*
*	Year barriers cannot be crossed for Month/Week/Quarter with the year in the	* 
*	  formula																	*
*********************************************************************************/

/* -- For Testing
DECLARE @PatternString NVARCHAR(2000)
  , @ReferenceDate DATE;
  
SET @PatternString = N'abc_{Q}_{+1}';
SET @ReferenceDate = '1/10/2005';
*/

        DECLARE @StringPosition INT ,
            @InReplaceBrackets BIT ,
            @ReturnString NVARCHAR(2000) ,
            @CurrentChar NCHAR(1) ,
            @StepReferenceDate DATE ,
            @LastReplacedType NCHAR(1) ,
            @NumToAdd INT;

        SET @StringPosition = 1;
        SET @InReplaceBrackets = 0;
        SET @ReturnString = '';

        WHILE @StringPosition < LEN(@PatternString) + 1
            BEGIN

                SET @CurrentChar = SUBSTRING(@PatternString, @StringPosition,
                                             1);

                IF ( @CurrentChar = N'{'
                     AND @InReplaceBrackets = 0
                   )
                    SET @InReplaceBrackets = 1;

                IF @InReplaceBrackets = 0
                    SET @ReturnString = @ReturnString + @CurrentChar;

                IF ( @CurrentChar = N'}'
                     AND @InReplaceBrackets = 1
                   )
                    SET @InReplaceBrackets = 0;

                IF @InReplaceBrackets = 1
                    BEGIN
			    /* So if there is a + we need to change the refrence date */
                        IF @CurrentChar = N'+'
                            BEGIN
						/* This is so we know the last thing we changed */
                                SET @CurrentChar = @LastReplacedType;
						/* Of course no-one will ever mess up a patteren.. but let's check anyway */
                                IF ISNUMERIC(SUBSTRING(@PatternString,
                                                       @StringPosition + 1, 1)) = 1
                                    SET @NumToAdd = SUBSTRING(@PatternString,
                                                              @StringPosition
                                                              + 1, 1);
                                ELSE
                                    SET @NumToAdd = 1;

						/* based on the last replaced value we add to the refrence date*/

                                SET @StepReferenceDate = CASE @LastReplacedType
					    /* Day Number */                   WHEN N'D'
                                                           THEN DATEADD(DAY,
                                                              @NumToAdd,
                                                              @ReferenceDate)
                        /* Week Number */                  WHEN N'W'
                                                           THEN DATEADD(WEEK,
                                                              @NumToAdd,
                                                              @ReferenceDate)
                        /* Month Number */                 WHEN N'M'
                                                           THEN DATEADD(MONTH,
                                                              @NumToAdd,
                                                              @ReferenceDate)
                        /* Year Number */                  WHEN N'Y'
                                                           THEN DATEADD(YEAR,
                                                              @NumToAdd,
                                                              @ReferenceDate)
                        /* Quarter  */                     WHEN N'Q'
                                                           THEN DATEADD(QUARTER,
                                                              @NumToAdd,
                                                              @ReferenceDate)
                                                           ELSE @ReferenceDate
                                                         END;
                            END;
                        ELSE
                            BEGIN
                                SET @StepReferenceDate = @ReferenceDate;
						/* We do this incase the next char is a + */
                                IF @CurrentChar IN ( N'W', N'M', N'Y', N'C',
                                                     N'Q' )
                                    SET @LastReplacedType = @CurrentChar;
                            END;

                        SET @ReturnString = CONCAT(@ReturnString,
                                                   CASE @CurrentChar
             /* Day Number */                        WHEN N'D'
                                                     THEN RIGHT('0'
                                                              + CAST(DATEPART(DAY,
                                                              @StepReferenceDate) AS NVARCHAR(2)),
                                                              2)
             /* Week Number */                       WHEN N'W'
                                                     THEN RIGHT('0'
                                                              + CAST(DATEPART(WEEK,
                                                              @StepReferenceDate) AS NVARCHAR(2)),
                                                              2)
			/* Month Number */                       WHEN N'M'
                                                     THEN RIGHT('0'
                                                              + CAST(DATEPART(MONTH,
                                                              @StepReferenceDate) AS NVARCHAR(2)),
                                                              2)
			/* Year Number */                        WHEN N'Y'
                                                     THEN RIGHT(CAST(DATEPART(YEAR,
                                                              @StepReferenceDate) AS NVARCHAR(4)),
                                                              2)

			/* Century Number */                     WHEN N'C'
                                                     THEN LEFT(CAST(DATEPART(YEAR,
                                                              @StepReferenceDate) AS NVARCHAR(4)),
                                                              2)
			/* Quarter  */                           WHEN N'Q'
                                                     THEN CONCAT('Q',
                                                              CAST(DATEPART(QUARTER,
                                                              @StepReferenceDate) AS NCHAR(1)))
                                                   END);
                    END;
                SET @StringPosition = @StringPosition + 1; 

            END;

        RETURN (@ReturnString);
    END;







