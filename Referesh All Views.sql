DECLARE @sqlcmd NVARCHAR(MAX) = ''
SELECT @sqlcmd = @sqlcmd +  'EXEC sp_refreshview ''['+ sc.name   + '].[' + so.name + ']'';
' 
FROM sys.objects AS so 
JOIN sys.schemas sc ON sc.schema_id = so.schema_id
WHERE so.type = 'V' 

SELECT @sqlcmd


