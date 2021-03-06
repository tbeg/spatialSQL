SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_makevalid(reloid text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
-- Intenta hacer que las geometrias invalidas de una capa sean validas sin perder vertices.
BEGIN

	EXECUTE 'UPDATE ' || reloid::text || ' SET the_geom = st_makevalid(the_geom) 
    WHERE st_isvalid(the_geom) = FALSE ';


	EXCEPTION
	WHEN others THEN
		RAISE EXCEPTION 'geoSICOB % (sicob_makevalid): % (%)', reloid, SQLERRM, SQLSTATE;	
END;
$function$
 