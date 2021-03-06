SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_snap_polyline2polyline(polyline_a geometry, polyline_b geometry)
 RETURNS geometry
 LANGUAGE plpgsql
AS $function$
DECLARE 
 new_borde geometry;
BEGIN

WITH
snapzone AS (
	SELECT st_union(ST_Buffer(polyline_a,  6::float/111000)) as the_geom
),
line_pol_b AS --Obteniendo las lineas del poligono poly_b dentro de la zona de snapping
(
    SELECT row_number() over() as segment, (dp).geom as the_geom, st_startpoint((dp).geom) as pini, st_endpoint((dp).geom) as pfin
    FROM(
        SELECT st_dump(the_geom) as dp  
        FROM (
          SELECT st_intersection(polyline_b, (SELECT the_geom from snapzone ) 
          ) as the_geom 
        ) r
    ) q
)
SELECT   sicob_snap_line2line(polyline_a, (SELECT st_union(the_geom) FROM line_pol_b)) into new_borde;
RETURN new_borde;     

EXCEPTION
WHEN others THEN
            RAISE EXCEPTION 'geoSICOB (sicob_snap_polyline2polyline): % (%)', SQLERRM, SQLSTATE;	
END;
$function$
 