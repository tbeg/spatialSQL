SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_geo_column(reloid text, _prefix text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
--DEVUELVE EL PRIMER CAMPO GEOMETRICO DE UNA TABLA, ANTECEDIENDO AL NOMBRE DEL CAMPO EL VALOR DE 'prefix'
--Call: SELECT * FROM sicob_geo_column('uploads.tt','poly.');
DECLARE 
  col text;
  __prefix text;
   tbl_name text; sch_name text;
BEGIN

SELECT * FROM sicob_split_table_name(reloid) INTO sch_name, tbl_name;

IF _prefix IS NOT NULL AND _prefix <> '' THEN
  __prefix := _prefix;
ELSE
  __prefix := reloid::text || '.';
END IF;

IF sch_name <> '' THEN
	SELECT f_geometry_column INTO col FROM geometry_columns
	WHERE 
	  f_table_schema = sch_name AND
	  f_table_name = tbl_name AND    
	  f_geometry_column <> 'the_geom_webmercator'
	LIMIT 1; 
ELSE
	--> intentando como tabla temporal
	SELECT f_geometry_column INTO col FROM geometry_columns
	WHERE 
	  f_table_schema like 'pg_temp%'  AND
	  f_table_name = tbl_name AND    
	  f_geometry_column <> 'the_geom_webmercator'
	LIMIT 1; 
END IF;

RETURN __prefix || '"' || COALESCE(col,'[no se encuentra sch:' || sch_name || ' , tbl: ' || tbl_name || ' ]' ) || '"';

EXCEPTION
WHEN others THEN
	RAISE EXCEPTION 'geoSICOB (sicob_geo_column):%,  % (%)', reloid::text , SQLERRM, SQLSTATE;
END;
$function$
 