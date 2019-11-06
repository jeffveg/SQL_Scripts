DECLARE
    @usrName VARCHAR(20),
    @newUsrName VARCHAR(50)

SET @usrName = 'FP'
SET @newUsrName = 'dbo'

SET nocount ON
DECLARE @uid INT
                   -- UID of the user
DECLARE @objName VARCHAR(50)
       -- Object name owned by user
DECLARE @currObjName VARCHAR(50)
   -- Checks for existing object owned by new user 
DECLARE @outStr VARCHAR(256)
       -- SQL command with 'sp_changeobjectowner'
SET @uid = USER_ID(@usrName)

DECLARE chObjOwnerCur CURSOR static
    FOR SELECT
            name
        FROM
            sysobjects
        WHERE
            uid = @uid

OPEN chObjOwnerCur
IF @@cursor_rows = 0 
    BEGIN
        PRINT 'Error: No objects owned by ' + @usrName
        CLOSE chObjOwnerCur
        DEALLOCATE chObjOwnerCur
    END
ELSE 
    BEGIN
        FETCH NEXT FROM chObjOwnerCur INTO @objName

        WHILE @@fetch_status = 0
            BEGIN
                SET @currObjName = @newUsrName + '.' + @objName
                IF ( OBJECT_ID(@currObjName) > 0 ) 
                    PRINT 'WARNING *** ' + @currObjName
                        + ' already exists ***'
                SET @outStr = 'sp_changeobjectowner ''' + @usrName + '.'
                    + @objName + ''',''' + @newUsrName + ''''
                PRINT @outStr
                PRINT 'go'
                FETCH NEXT FROM chObjOwnerCur INTO @objName
            END
        CLOSE chObjOwnerCur
        DEALLOCATE chObjOwnerCur
    END



