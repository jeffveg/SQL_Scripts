
/* declare variables */
DECLARE
    @ColumnList NVARCHAR(4000)
  , @SQL NVARCHAR(4000)
  , @ColName sysname
  , @IsComput BIT
  , @TableName sysname;

SET @TableName = 'XRefHotelChain';

SET @ColumnList = '';
SET @SQL = '';
DECLARE cursor_name CURSOR FAST_FORWARD READ_ONLY
FOR
    SELECT
        c.name
      , c.is_computed
    FROM
        sys.objects AS o
    JOIN sys.columns AS c
        ON c.object_id = o.object_id
    WHERE
        o.name = @TableName
    ORDER BY
        c.column_id;

OPEN cursor_name;

FETCH NEXT FROM cursor_name INTO @ColName, @IsComput;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @IsComput = 0
    BEGIN

        SET @ColumnList = @ColumnList + '[' + @ColName + '],';
    END;
    ELSE
    BEGIN
        SET @ColumnList = @ColumnList + '--' + @ColName + ',';
    END;
    FETCH NEXT FROM cursor_name INTO @ColName, @IsComput;
END;

CLOSE cursor_name;
DEALLOCATE cursor_name;

SET @ColumnList = LEFT(@ColumnList, LEN(@ColumnList) - 1);

PRINT 'PRINT ''Copying data for ' + @TableName + '''';
PRINT 'SET IDENTITY_INSERT dbo.[' + @TableName + '] ON;';
PRINT 'INSERT  INTO dbo.[' + @TableName + '] (' + @ColumnList + ')';
PRINT 'SELECT ' + @ColumnList; 
PRINT 'FROM';
PRINT '    [US-SV-DW03].ICEDW.dbo.[' + @TableName + '];';
PRINT '	SET IDENTITY_INSERT dbo.[' + @TableName + '] OFF;';

