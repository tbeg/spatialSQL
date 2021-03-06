SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_add_geoinfo_column(table_name text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
  sql TEXT;
BEGIN
--ADICIONA CAMPOS DE INFORMACION GEOGRAFICA
-------------------------------------------	
	IF SICOB_exist_column(table_name, 'sicob_sup') = FALSE THEN
		sql := Format('ALTER TABLE %s ADD COLUMN sicob_sup double precision', table_name);
		EXECUTE sql;
    END IF;
    
	IF SICOB_exist_column(table_name, 'sicob_utm') = FALSE THEN
		sql := Format('ALTER TABLE %s ADD COLUMN sicob_utm int', table_name);
		EXECUTE sql;
    END IF;
    
	IF SICOB_exist_column(table_name, 'the_geom_webmercator') = FALSE THEN
		sql := Format('ALTER TABLE %s ADD COLUMN the_geom_webmercator geometry(Geometry,3857)', table_name);
		EXECUTE sql;
    END IF;    

/*
	IF SICOB_exist_column(table_name, 'the_geom_webmercator') THEN
    	sql := Format('ALTER TABLE %s DROP COLUMN the_geom_webmercator', table_name);
		EXECUTE sql; 
    END IF; 
	sql := Format('ALTER TABLE %s ADD COLUMN the_geom_webmercator geometry(Geometry,3857)', table_name);
	EXECUTE sql;
    
	IF SICOB_exist_column(table_name, 'sicob_sup') THEN
    	sql := Format('ALTER TABLE %s DROP COLUMN sicob_sup', table_name);
		EXECUTE sql;
    END IF;
	sql := Format('ALTER TABLE %s ADD COLUMN sicob_sup double precision', table_name);
	EXECUTE sql;
 */
 	
END;
$function$
 