-- CREATE AND fill the table

CREATE TABLE Inventory
    (
     Part_Number INT
   , Quantity INT
    );

INSERT  INTO dbo.Inventory
        (Part_Number, Quantity)
VALUES  (1  -- Part_Number - int
         , 200  -- Quantity - int
         );

INSERT  INTO dbo.Inventory
        (Part_Number, Quantity)
VALUES  (2  -- Part_Number - int
         , 0  -- Quantity - int
         );

INSERT  INTO dbo.Inventory
        (Part_Number, Quantity)
VALUES  (3  -- Part_Number - int
         , 200  -- Quantity - int
         );

INSERT  INTO dbo.Inventory
        (Part_Number, Quantity)
VALUES  (4  -- Part_Number - int
         , 200  -- Quantity - int
         );

-- Read Past -----------------------------------------------

BEGIN TRANSACTION;

UPDATE  dbo.Inventory
SET     Quantity = Quantity - 6
WHERE   Part_Number = 4;

-- Don't commit yet! Run this in another connection
SELECT  *
FROM    dbo.Inventory WITH (READPAST);

COMMIT; 



--READ UNCOMMITTED -----------------------------------------------

BEGIN TRANSACTION; 
UPDATE  dbo.Inventory
SET     Quantity = Quantity + 6
WHERE   Part_Number = 2;


-- Don't commit yet! Run this in another connection
SELECT  *
FROM    dbo.Inventory WITH (READUNCOMMITTED);

ROLLBACK;

-- Run this again in the other window 
SELECT  *
FROM    dbo.Inventory WITH (READPAST);

-- Clean up the table
DROP TABLE dbo.Inventory;