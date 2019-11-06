
/* get the latest records of the drive */
SELECT  d.SLID
      , LEFT(d.Name, 1) DriveLeter
      , d.FreeSpace
      , d.Capacity
      , d.Label
INTO    #Drives
FROM    dbo.DriveHistory d
        JOIN (SELECT    SLID
                      , Name
                      , MAX(DateInserted) DateInserted
              FROM      dbo.DriveHistory
              WHERE     DriveType > 0
                        AND LEFT(Name, 1) <> '\'
              GROUP BY  SLID
                      , Name) f
            ON f.SLID = d.SLID
               AND f.Name = d.Name
               AND f.DateInserted = d.DateInserted;

/* if we have a manual override to use the manual table then delete the data */
DELETE  #Drives
FROM    dbo.DriveManual dm
        LEFT JOIN #Drives d
            ON d.SLID = dm.SLID
               AND dm.Name = d.DriveLeter
WHERE   dm.ForceOverride = 1;

/* get the missing data if it's in the manual table */

INSERT  INTO #Drives
        (SLID
       , DriveLeter
       , FreeSpace
       , Capacity
       , Label
        )
        SELECT  dm.SLID
              , dm.Name
              , -1
              , dm.Capacity
              , dm.Label
        FROM    dbo.DriveManual dm
                LEFT JOIN #Drives d
                    ON d.SLID = dm.SLID
        WHERE   d.SLID IS NULL;


SELECT  db.DatabaseSiseID
      , db.SLID
      , db.DatabaseName
      , db.FileGroupName
      , db.size
      , db.max_size
      , db.growth
      , db.is_percent_growth
      , db.DriveLetter
      , db.FileType
      , db.SpaceUsed
INTO    #Databases
FROM    dbo.DatabaseSizeHistory db
        JOIN (SELECT    ds.SLID
                      , ds.DatabaseName
                      , ds.FileGroupName
                      , ds.DriveLetter
                      , ds.FileType
                      , MAX(ds.DateInserted) DateInserted
              FROM      dbo.DatabaseSizeHistory ds
              GROUP BY  ds.SLID
                      , ds.DatabaseName
                      , ds.FileGroupName
                      , ds.DriveLetter
                      , ds.FileType) f
            ON f.SLID = db.SLID
               AND f.DatabaseName = db.DatabaseName
               AND f.FileGroupName = db.FileGroupName
               AND f.DriveLetter = db.DriveLetter
               AND f.FileType = db.FileType
               AND f.DateInserted = db.DateInserted;

SELECT  sl.DisplayName
      , dh.DriveLeter
      , dh.FreeSpace
      , dh.Capacity
      , dh.Label
      , ds.DatabaseName
      , ds.size
      , ds.max_size
      , ds.growth
      , ds.is_percent_growth
      , ds.DriveLetter
      , ds.FileType
      , ds.SpaceUsed
FROM    dbo.Server_List sl
        LEFT JOIN #Drives dh
            ON dh.SLID = sl.SLID
        LEFT JOIN #Databases ds
            ON ds.SLID = dh.SLID
               AND ds.DriveLetter = dh.DriveLeter
			   
			   --WHERE dh.DriveLeter IS NULL 

			   ORDER BY size , sl.slid;

GO 
DROP TABLE #Drives;
DROP TABLE #Databases;

