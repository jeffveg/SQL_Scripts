  
					   
DECLARE cTextSearch CURSOR READ_ONLY
FOR
SELECT  tables.name AS TableName
      , columns.name AS ColumnName
FROM    sys.tables
        JOIN sys.columns
            ON COLUMNS.object_id = TABLES.object_id
        JOIN sys.types
            ON types.system_type_id = COLUMNS.system_type_id
WHERE   types.name IN ('varchar', 'XML', 'text', 'nvarchar', 'ntext', 'NCHAR',
                       'CHAR');
					

DECLARE @TableName sysname
  , @ColumnName sysname
  , @DataType sysname
  , @SearchString NVARCHAR(100)
  , @SQL NVARCHAR(2000)
  , @ParmDefinition NVARCHAR(100)
  , @RowCount INT;


SET @SearchString = 'vegas1.jpg';

OPEN cTextSearch;

FETCH NEXT FROM cTextSearch INTO @TableName, @ColumnName;
WHILE (@@fetch_status <> -1)
    BEGIN
        IF (@@fetch_status <> -2)
            BEGIN
                PRINT '-- Searching Table:' + @TableName + ' Column:'
                    + @ColumnName;  
		
                SET @SQL = 'Select @Count_OUT = count(*) from [' + @TableName
                    + '] WHERE cast( [' + @ColumnName
                    + '] as nvarchar(max)) like ''%' + @SearchString + '%'';';


                SET @ParmDefinition = N'@Count_OUT int OUTPUT';

                EXECUTE sp_executesql @SQL, @ParmDefinition,
                    @Count_OUT = @RowCount OUTPUT;
                IF @RowCount > 0
                    BEGIN
                        SET @SQL = 'Select * from [' + @TableName
                            + '] WHERE [' + @ColumnName + '] like ''%'
                            + @SearchString + '%'';';

                        PRINT @SQL;
                    END;

            END;
        FETCH NEXT FROM cTextSearch INTO @TableName, @ColumnName;
    END;

CLOSE cTextSearch;
DEALLOCATE cTextSearch;
GO

