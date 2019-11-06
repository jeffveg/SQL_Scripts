USE neo_prod

DROP TABLE IF EXISTS neo_prod_aux..backup_eob_release
SELECT * INTO neo_prod_aux..backup_eob_release FROM eob_release WHERE eob_key = (SELECT MAX(eob_key) FROM eob_release)

DROP TABLE IF EXISTS neo_prod_aux..backup_eob_release_line_item
SELECT * INTO neo_prod_aux..backup_eob_release_line_item FROM Eob_Release_Line_Item WHERE eob_key =  (SELECT MAX(eob_key) FROM eob_release)

TRUNCATE TABLE eob_release
TRUNCATE TABLE eob_release_line_item

INSERT INTO eob_release SELECT * FROM neo_prod_aux..backup_eob_release
INSERT INTO eob_release_line_item SELECT * FROM neo_prod_aux..backup_eob_release_line_item