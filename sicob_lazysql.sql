SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_lazysql(sql text, t real DEFAULT 1)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
	PERFORM pg_sleep(t);
	RAISE DEBUG 'Running %', sql;
    EXECUTE sql;
EXCEPTION
	WHEN others THEN
    	RAISE EXCEPTION 'geoVision [sicob_lazysql], time: %, sql: %, % (%)', t, sql , SQLERRM, SQLSTATE;
END;
$function$
 