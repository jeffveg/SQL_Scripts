SELECT  CONCAT('GRANT VIEW DEFINITION ON ', name,
               ' TO [ICEENTERPRISE\developers]')
FROM    sys.objects
WHERE   schema_id = 1
        AND type = 'P'
        AND is_ms_shipped = 0;