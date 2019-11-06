ALTER FUNCTION PartitionCreate.CaculateRefDate
    (
      @Frequency NCHAR(1) ,
      @FrequencyInterval INT ,
      @Today DATE
    )
RETURNS DATE

/********************************************************************************
* CaculateRefDate 																*
* This is used for the Partition Create proc no other use is implied			*
* Several time I need caculate the ref date so lets make this a function{ }		*
* W = Week number																*
* M = Month Number																*
* Y = last 2 digits of Year														*
* Q = Quarter Number															*
*********************************************************************************/
AS
    BEGIN
        DECLARE @RefDate DATE;

		/* in case there is no caculation made return the date given */
		SET @RefDate = @Today;
		
		/* Week */
        IF @Frequency = 'W'
            BEGIN
                SET @RefDate = DATEADD(WEEK, @FrequencyInterval, @Today);
				/* set to Sunday of that week */
                SET @RefDate = DATEADD(DAY,
                                       ( DATEPART(WEEKDAY, @RefDate) - 1 )
                                       * -1, @RefDate);
							   
            END;
		/* Month */
        IF @Frequency = 'M'
			/* Set to first day of the next month */
            SET @RefDate = DATEADD(DAY, 1,
                                   EOMONTH(DATEADD(MONTH, @FrequencyInterval -1 ,
                                                   @Today)));
		/* Quarter */
        IF @Frequency = 'Q'
            BEGIN
                SET @RefDate = DATEADD(QUARTER, @FrequencyInterval, @Today);
				/* Set to first day of new that quarter */
                SET @RefDate = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @RefDate),
                                       0);
            END;
		/* Year */
        IF @Frequency = 'Y'
            BEGIN
                SET @RefDate = DATEADD(YEAR, @FrequencyInterval, @Today);
				/* Set it to the first of the that year */
                SET @RefDate = DATEFROMPARTS(DATEPART(YEAR, @RefDate), 1, 1);             
            END;

        RETURN @RefDate;
    END;