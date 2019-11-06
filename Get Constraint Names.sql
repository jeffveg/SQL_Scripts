
SELECT 
c_obj.NAME AS ConstraintName,
T_obj.NAME AS TableName,
col.NAME AS ColumnName


FROM sysobjects c_obj
 JOIN sysobjects t_obj ON c_obj.parent_obj = t_obj.id
 JOIN sysconstraints con ON c_obj.id = con.constid
 JOIN syscolumns col ON t_obj.id = col.id
  AND con.colid = col.colid

WHERE c_obj.NAME LIKE '%?'