CREATE OR REPLACE FUNCTION public.sicob_to_geojson(_opt json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
  my_result json;
BEGIN	
--PARAMETROS EN VARIABLE _opt
  --lyr_in, <-- capa PostGIS a convertir 
  --condition TEXT  <-- (opcional) condicion para el filtro WHERE

    EXECUTE 'SELECT row_to_json(fc)
     FROM ( 
       SELECT ''FeatureCollection'' AS type, array_to_json(array_agg(f)) AS features
       FROM ( 
         SELECT 
           ''Feature'' AS type,
           public.ST_AsGeoJSON(the_geom,5)::json AS geometry,
           row_to_json((SELECT p FROM (
             SELECT -- Modify followinf cols from table t if needed:
               ' || public.sicob_no_geo_column(_opt->>'lyr_in','{}','t.') || '
             ) AS p)) AS properties
         FROM ' || (_opt->>'lyr_in')::text || ' AS t -- <- Set your table here
         WHERE TRUE ' || COALESCE( 'AND (' ||  (_opt->>'condition')::text || ')', '') || ' -- <- Set some constraint if needed
         ORDER BY sicob_id LIMIT 50
       ) AS f
     ) AS fc' INTO my_result;
     RETURN my_result;
END;
$function$
 