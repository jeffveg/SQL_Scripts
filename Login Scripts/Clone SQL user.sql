            BEGIN TRY /* This is so I can run the script again and again */
                DROP PROCEDURE #MyForEach
            END TRY

            BEGIN CATCH
            END CATCH;
			GO

            CREATE PROCEDURE #MyForEach (@CMD NVARCHAR(MAX))
            AS
            DECLARE @dbs CURSOR
              , @cmd2Run NVARCHAR(MAX)
              , @db NVARCHAR(128)
              , @sp NVARCHAR(255)
            SET @dbs = CURSOR STATIC
			FOR
			SELECT name
			FROM sys.databases
			WHERE state = 0;/* State 0 = online */

            OPEN @dbs;

            WHILE (1 = 1)
                BEGIN
                    FETCH @dbs INTO @db;

                    IF @@FETCH_STATUS <> 0
                        BREAK;

                    SET @cmd2Run = REPLACE(@CMD, '?', @db)
                    SET @sp = QUOTENAME(@db) + N'.sys.sp_executesql';

                    BEGIN TRY
                        EXEC @sp @cmd2Run;
                    END TRY

                    BEGIN CATCH
                    END CATCH;
                END;
			GO

            USE [master]
GO
            CREATE LOGIN [ICEENTERPRISE\SP13_PPUnattendedTes] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO

            DECLARE @SQL NVARCHAR(2000)
              , @ID_To_Clone VARCHAR(35)
              , @New_ID VARCHAR(35)

            SET @ID_To_Clone = 'ICEENTERPRISE\spps_secureperfpoint'
            SET @New_ID = 'ICEENTERPRISE\SP13_PPUnattendedTes'


-- exec sp_msforeachdb 'use [?]; drop schema [EXPORTER]; drop user [EXPORTER];'

            SET @SQL = 'use [?]
DECLARE @N sysname, @D sysname, @C char(2)
select  @D=''' + @ID_To_Clone + ''',@N=''' + @New_ID
                + ''',@C=CHAR(13)+CHAR(10)
SET NOCOUNT ON
DECLARE @g varchar(8000), @U smallint, @S sysname, @RN varchar(8000), @O int, @ON varchar(261)
SELECT  @U=u.uid, @S=l.[loginname] FROM sysusers u LEFT JOIN master..syslogins l ON u.[sid]=l.sid WHERE l.name=@D
IF @u IS NOT NULL 
BEGIN
SET @g=''USE [''+DB_NAME()+'']''+@C+''GO''+@C+''EXEC sp_grantdbaccess [''+@N+''], [''+@N+'']''+@C+''GO''
PRINT @g
DECLARE _u CURSOR LOCAL READ_ONLY FOR SELECT name FROM sysusers WHERE uid IN (SELECT groupuid FROM sysmembers WHERE memberuid=@U)
OPEN _u FETCH NEXT FROM _u INTO @RN
WHILE @@FETCH_STATUS=0
BEGIN
SET @g=''EXEC sp_addrolemember [''+@RN+''], [''+@N+'']''
PRINT @g
FETCH NEXT FROM _u INTO @RN
END
SET @g=''GO''
PRINT @g
DECLARE _o CURSOR LOCAL READ_ONLY FOR SELECT DISTINCT (o.id), ''[''+USER_NAME(o.uid)+''].[''+o.name+'']'' FROM sysprotects p INNER JOIN sysobjects o ON p.id=o.id WHERE p.uid=@U
OPEN _o
FETCH NEXT FROM _o INTO @O, @ON
WHILE @@FETCH_STATUS=0
BEGIN
SET @g=''''
IF EXISTS(SELECT * FROM sysprotects WHERE id=@O AND uid=@U AND action=193 AND protecttype=205)
SET @g=@g+''SELECT,''
IF EXISTS ( SELECT * FROM sysprotects WHERE id=@O AND uid=@U AND action=195 AND protecttype=205)
SET @g=@g+''INSERT,''
IF EXISTS(SELECT * FROM sysprotects WHERE id=@O AND uid=@U AND action=197 AND protecttype=205)
SET @g=@g+''UPDATE,''
IF EXISTS(SELECT * FROM sysprotects WHERE id=@O AND uid=@U AND action=196 AND protecttype=205)
SET @g=@g+''DELETE,''
IF EXISTS(SELECT * FROM sysprotects WHERE id=@O AND uid=@U AND action=224 AND protecttype=205)
SET @g=@g+''EXECUTE,''
if len(@G)>1
PRINT ''GRANT ''+ left(@g,len(@g)-1) + '' ON OBJECT::'' + @ON + '' TO ['' + @N + '']''
FETCH NEXT FROM _o INTO @O,@ON
END
CLOSE _o
DEALLOCATE _o
CLOSE _u
DEALLOCATE _u
END'

   --PRINT LEN(@SQL) 
   --PRINT @SQL
   
   
   EXEC #MyForEach @SQL
   

