CREATE FUNCTION dbo.fnIsValidCard
(
@TheCard VARCHAR(20)
)
RETURNS TINYINT
AS
BEGIN
       RETURN (SELECT CASE
              WHEN Card LIKE '%[^0-9]%' THEN 0
              WHEN Card IS NULL THEN 0
              WHEN   (
                     + 2 * cast(substring(Card, 1, 1) AS TINYINT) / 10
                     + 2 * cast(substring(Card, 1, 1) AS TINYINT) % 10
                     + cast(substring(Card, 2, 1) AS TINYINT)
                     + 2 * cast(substring(Card, 3, 1) AS TINYINT) / 10
                     + 2 * cast(substring(Card, 3, 1) AS TINYINT) % 10
                     + cast(substring(Card, 4, 1) AS TINYINT)
                     + 2 * cast(substring(Card, 5, 1) AS TINYINT) / 10
                     + 2 * cast(substring(Card, 5, 1) AS TINYINT) % 10
                     + cast(substring(Card, 6, 1) AS TINYINT)
                     + 2 * cast(substring(Card, 7, 1) AS TINYINT) / 10
                     + 2 * cast(substring(Card, 7, 1) AS TINYINT) % 10
                     + cast(substring(Card, 8, 1) AS TINYINT)
                     + 2 * cast(substring(Card, 9, 1) AS TINYINT) / 10
                     + 2 * cast(substring(Card, 9, 1) AS TINYINT) % 10
                     + cast(substring(Card, 10, 1) AS TINYINT)
                     + 2 * cast(substring(Card, 11, 1) AS TINYINT) / 10
                     + 2 * cast(substring(Card, 11, 1) AS TINYINT) % 10
                     + cast(substring(Card, 12, 1) AS TINYINT)
                     + 2 * cast(substring(Card, 13, 1) AS TINYINT) / 10
                     + 2 * cast(substring(Card, 13, 1) AS TINYINT) % 10
                     + cast(substring(Card, 14, 1) AS TINYINT)
                     + 2 * cast(substring(Card, 15, 1) AS TINYINT) / 10
                     + 2 * cast(substring(Card, 15, 1) AS TINYINT) % 10
                     + cast(substring(Card, 16, 1) AS TINYINT)
                     + 2 * cast(substring(Card, 17, 1) AS TINYINT) / 10
                     + 2 * cast(substring(Card, 17, 1) AS TINYINT) % 10
                     + cast(substring(Card, 18, 1) AS TINYINT)
                     + 2 * cast(substring(Card, 19, 1) AS TINYINT) / 10
                     + 2 * cast(substring(Card, 19, 1) AS TINYINT) % 10
                     + cast(substring(Card, 20, 1) AS TINYINT)
              ) % 10 = 0 THEN 1
              ELSE 0
       END FROM (
             VALUES (
                  convert(CHAR(20),
                  CASE WHEN len(@TheCard)%2=1 THEN '0' ELSE '' END
                     +@TheCard+'00000000'
                     )
                )
           )f(card))
END