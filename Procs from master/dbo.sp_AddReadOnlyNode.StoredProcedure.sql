/****** Object:  StoredProcedure [dbo].[sp_AddReadOnlyNode]    Script Date: 3/12/2019 10:42:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[sp_AddReadOnlyNode]
    (
      @NodeToAdd sysname
    , @AGName NVARCHAR(256) = NULL
    )
AS
    DECLARE
        @SQL NVARCHAR(4000)
      , @Quote NCHAR(1)
      , @CRLF NCHAR(2)
      , @NodeName NVARCHAR(100)
      , @PrimaryNodeName NVARCHAR(100)
      , @NodeList NVARCHAR(4000)
      , @OtherNodes NVARCHAR(4000)
      , @AGID UNIQUEIDENTIFIER
      , @LastComma INT;

    SET @Quote = '''';
    SET @CRLF = CHAR(13) + CHAR(10);

    IF @AGName IS NULL
    BEGIN
        SELECT
            @AGName = name
          , @AGID = group_id
        FROM
            sys.availability_groups;
	
    END;
    ELSE
    BEGIN
        SELECT
            @AGID = group_id
        FROM
            sys.availability_groups
        WHERE
            @AGName = name;
    END;
		
    SELECT
        @PrimaryNodeName = ar.replica_server_name
    FROM
        sys.dm_hadr_availability_replica_states AS hars
    JOIN sys.dm_hadr_name_id_map AS map
        ON hars.group_id = map.ag_id
    JOIN sys.availability_replicas AS ar
        ON hars.replica_id = ar.replica_id
    WHERE
        hars.is_local = 1
        AND hars.role = 1
        AND hars.operational_state = 2
        AND map.ag_name = @AGName; 

    SELECT
        @OtherNodes = COALESCE(@OtherNodes + ',', '') + ar.replica_server_name
    FROM
        sys.dm_hadr_availability_replica_states AS hars
    JOIN sys.availability_replicas AS ar
        ON hars.replica_id = ar.replica_id
    WHERE
        ar.group_id = @AGID
        AND ar.availability_mode = 1
    ORDER BY
        hars.role DESC; 

    SET @OtherNodes = @Quote + REPLACE(@OtherNodes, ',', @Quote + ',' + @Quote)
        + @Quote;
		
    IF (
         SELECT
            COUNT(*)
         FROM
            sys.availability_replicas AS ar2
         WHERE
            ar2.group_id = @AGID
            AND ar2.replica_server_name = @NodeToAdd
       ) = 0
    BEGIN
        RAISERROR ('The node provided does not exist',16,1);
		RETURN;
    END;

    SELECT
        @NodeList = COALESCE(@NodeList + ',', '') + a.replica_server_name
    FROM
        (
          SELECT
            ar2.replica_server_name AS replica_server_name
          FROM
            sys.availability_read_only_routing_lists AS arorl
          JOIN
            sys.availability_replicas AS ar
            ON arorl.replica_id = ar.replica_id
          JOIN
            sys.availability_replicas AS ar2
            ON arorl.read_only_replica_id = ar2.replica_id
          WHERE
            ar.replica_server_name = @PrimaryNodeName
            AND ar.group_id = @AGID
            AND ar2.group_id = @AGID
            AND arorl.routing_priority = 1
          UNION
          SELECT
            @NodeToAdd
        ) AS a;
	
    SET @NodeList = @Quote + REPLACE(@NodeList, ',', @Quote + ',' + @Quote)
        + @Quote;

    DECLARE @variable INT;

    DECLARE cFailOverNodes CURSOR FAST_FORWARD READ_ONLY
    FOR
        SELECT
            ar.replica_server_name
        FROM
            sys.dm_hadr_availability_replica_states AS hars
        JOIN sys.availability_replicas AS ar
            ON hars.replica_id = ar.replica_id
        WHERE
            ar.group_id = @AGID
            AND ar.availability_mode = 1
        ORDER BY
            hars.role ASC;

    OPEN cFailOverNodes;

    FETCH NEXT FROM cFailOverNodes INTO @NodeName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
    
        SET @SQL = 'ALTER AVAILABILITY GROUP [' + @AGName
            + '] MODIFY REPLICA ON ';
        SET @SQL += 'N' + @Quote + @NodeName + @Quote + @CRLF;
        SET @SQL += ' WITH (PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=((';
        SET @SQL += @NodeList + '),' + @OtherNodes + ')));';
  
        PRINT @SQL;
        EXEC sys.sp_executesql
            @SQL;

        SET @LastComma = LEN(@OtherNodes) - CHARINDEX(',',
                                                      REVERSE(@OtherNodes))
            + 2;
        SET @OtherNodes = SUBSTRING(@OtherNodes, @LastComma, LEN(@OtherNodes))
            + ',' + SUBSTRING(@OtherNodes, 1, @LastComma - 2);
  
        FETCH NEXT FROM cFailOverNodes INTO @NodeName;
    END;

    CLOSE cFailOverNodes;
    DEALLOCATE cFailOverNodes;


GO
