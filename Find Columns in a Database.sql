SELECT
    o.NAME AS TableName,
    c.NAME,
    CASE c.xtype
      WHEN 34 THEN 'image'
      WHEN 35 THEN 'text'
      WHEN 36 THEN 'uniqueidentifier'
      WHEN 48 THEN 'tinyint'
      WHEN 52 THEN 'smallint'
      WHEN 56 THEN 'int'
      WHEN 58 THEN 'smalldatetime'
      WHEN 59 THEN 'real'
      WHEN 60 THEN 'money'
      WHEN 61 THEN 'datetime'
      WHEN 62 THEN 'float'
      WHEN 98 THEN 'sql_variant'
      WHEN 99 THEN 'ntext'
      WHEN 104 THEN 'bit'
      WHEN 106 THEN 'decimal'
      WHEN 108 THEN 'numeric'
      WHEN 122 THEN 'smallmoney'
      WHEN 127 THEN 'bigint'
      WHEN 165 THEN 'varbinary'
      WHEN 167 THEN 'varchar'
      WHEN 173 THEN 'binary'
      WHEN 175 THEN 'char'
      WHEN 189 THEN 'timestamp'
      WHEN 231 THEN 'nvarchar'
      WHEN 231 THEN 'sysname'
      WHEN 239 THEN 'nchar'
      WHEN 241 THEN 'xml'
      ELSE 'Who Knows'
    END AS DataType,
    prec,
    scale,
    LENGTH
FROM
    syscolumns c
    JOIN sysobjects o
        ON c.id = o.id
WHERE
    c.NAME LIKE '%prod_id%'
    AND o.xtype = 'U'