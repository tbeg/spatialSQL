SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_feature_id(reloid regclass)
 RETURNS character varying
 LANGUAGE plpgsql
 IMMUTABLE STRICT
AS $function$
DECLARE
	fldname varchar;
BEGIN
--DEVUELVE EL nombre del campo id de una tabla feature de postgis
-----------------------------------------------------------------------------------------
	fldname := NULL;
    with
    flds as (
        SELECT column_name, pg_get_serial_sequence(reloid::text, column_name) as sq
        FROM information_schema.columns c, (SELECT * FROM sicob_split_table_name(reloid::text) ) t
        WHERE c.table_schema=t.schema_name AND c.table_name = t.table_name
          ORDER BY ordinal_position
    )
    SELECT column_name into fldname FROM flds
    WHERE sq IS NOT NULL ; 
     
 	IF NOT FOUND THEN
	   RAISE DEBUG 'sicob_feature_id: No se ha encontrado el campo id del feature "%"',reloid::text;
	END IF;
    
    return fldname;   
    
END;
$function$
 