USE pubs

DECLARE @TableName SYSNAME
DECLARE @indid INT

DECLARE cur_tblfetch CURSOR
FOR
SELECT table_name
FROM information_schema.tables
WHERE table_type = 'base table'

OPEN cur_tblfetch

FETCH NEXT
FROM cur_tblfetch
INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE cur_indfetch CURSOR
	FOR
	SELECT indid
	FROM sysindexes
	WHERE id = OBJECT_ID(@TableName)
		AND keycnt > 0

	OPEN cur_indfetch

	FETCH NEXT
	FROM cur_indfetch
	INTO @indid

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT 'Derfagmenting index_id = ' + convert(CHAR(3), @indid) + 'of the ' + rtrim(@TableName) + ' table'

		IF @indid <> 255
			DBCC INDEXDEFRAG (
					pubs,
					@TableName,
					@indid
					)

		FETCH NEXT
		FROM cur_indfetch
		INTO @indid
	END

	CLOSE cur_indfetch

	DEALLOCATE cur_indfetch

	FETCH NEXT
	FROM cur_tblfetch
	INTO @TableName
END

CLOSE cur_tblfetch

DEALLOCATE cur_tblfetch
