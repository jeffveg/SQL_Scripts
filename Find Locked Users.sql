SELECT  name
FROM    sys.server_principals
WHERE   is_disabled = 0 
        and CAST(LoginProperty(name, 'IsLocked') AS INT) = 1
