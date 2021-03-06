SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_clear_schema(schname text)
 RETURNS void
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  sql text;

BEGIN
 

      SELECT string_agg(droptable, '; ') into sql
      FROM (
          select 'drop table "' || schemaname || '"."' || tablename || '" cascade' as droptable 
          from pg_tables
          where schemaname = 'temp'
          limit 1000
      ) t; 


        EXECUTE sql;


 
EXCEPTION
WHEN others THEN
            RAISE EXCEPTION 'geoSICOB (sicob_clear_schema):schname:% >> % (%)', schname, SQLERRM, SQLSTATE;	
END;
$function$
 