USE [ETLStaging_Token]
GO

/****** Object:  StoredProcedure [dbo].[TokenInsert]    Script Date: 1/9/2018 5:19:01 PM ******/
DROP PROCEDURE [dbo].[TokenInsert]
GO

DROP TABLE dbo.TokenStaging;

CREATE TABLE dbo.TokenStaging
    (
        NameID BIGINT NULL
	  , PartnerID INT NOT NULL
      , Token VARCHAR(8000) NULL
      , InsertDate DATETIME2 NOT NULL
            CONSTRAINT df_DateTime
                DEFAULT ( SYSDATETIME())
      --, CONSTRAINT pk_TokenStaging
            --PRIMARY KEY NONCLUSTERED ( TokenStagingID )

			INDEX ix_TokenStagingPartner HASH (PartnerID) WITH (BUCKET_COUNT = 500)
    )
WITH ( MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_ONLY );
GO

CREATE PROCEDURE [dbo].[TokenInsert]
    (
        @NameID BIGINT
	  , @PartnerID INT	
      , @Token VARCHAR(8000)
    )
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH ( TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'English' )

    --DECLARE @InsertDate DATETIME = SYSDATETIME();

    INSERT INTO dbo.TokenStaging (
                                     NameID
								   , PartnerID
								   , Token
                                --   , InsertDate
                                 )
    VALUES (
               @NameID, @PartnerID, @Token--, @InsertDate
           );

END;
GO

GRANT EXEC ON dbo.TokenInsert TO jwtsvc



EXEC TokenInsert
    1585,101
  , 'ldlfkmeoasldfm405q34mkfermcv0we45tojkwerlfojq3049jrt;lekrmf[3495u;erklfgq;owei45tu[q094utef904fm320
ldlfkmeoasldfm405q34mkfermcv0we45tojkwerlfojq3049jrt;lekrmf[3495u;erklfgq;owei45tu[q094utef904fm320
ldlfkmeoasldfm405q34mkfermcv0we45tojkwerlfojq3049jrt;lekrmf[3495u;erklfgq;owei45tu[q094utef904fm320
ldlfkmeoasldfm405q34mkfermcv0we45tojkwerlfojq3049jrt;lekrmf[3495u;erklfgq;owei45tu[q094utef904fm320
ldlfkmeoasldfm405q34mkfermcv0we45tojkwerlfojq3049jrt;lekrmf[3495u;erklfgq;owei45tu[q094utef904fm320

';


INSERT INTO dbo.TokenStaging (
                                 NameID
                               , Token
                             )
VALUES (
           1585, 'ReallyBigTokenHere'
       );



EXEC TokenInsert 1585, 105, 'ReallyBigTokenHere';


DELETE  dbo.TokenStaging

SELECT COUNT(*) FROM dbo.TokenStaging


SELECT * FROM dbo.TokenStaging

INSERT INTO dbo.TokenStaging 
SELECT 
    NameID
     , 108,Token
     , InsertDate FROM dbo.TokenStaging
	 WHERE partnerid = 101



	 SELECT COUNT(*) FROM dbo.TokenStaging



select * from sys.dm_db_xtp_table_memory_stats  
where object_id = object_id('dbo.TokenStaging')  

	 DELETE dbo.TokenStaging WHERE PartnerID = 108

SELECT partnerid ,COUNT(*) FROM dbo.TokenStaging group BY partnerid