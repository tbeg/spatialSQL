SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_snap_line2line(line_a geometry, line_b geometry, _tolerance double precision)
 RETURNS geometry
 LANGUAGE plpgsql
AS $function$
DECLARE 
 new_line geometry;
BEGIN

	WITH
	P2 AS (
		SELECT (dp).path[1] As id,(dp).geom As the_geom
		FROM (
			SELECT ST_DumpPoints(line_b) as dp 
   		) pts
	),
    ptsL2toL1 as (
    SELECT points_to_project_onto_line.id, 
    ST_LineInterpolatePoint(
            line_a,
            ST_LineLocatePoint(
                line_a,
                points_to_project_onto_line.the_geom
            )
        ) as the_geom
    FROM P2 points_to_project_onto_line
    ),
    cutlineL1 AS (
        SELECT sicob_cutlineatpoints(line_a,
        ( SELECT st_union(the_geom) FROM ptsL2toL1 ), 0.00005
        ) as the_geom
    ),
    snapL2toL1 AS (
        SELECT ST_Snap(
            (SELECT st_union(the_geom) FROM cutlineL1),    
            line_b,
            _tolerance) as the_geom 
    ) 
    SELECT   st_union(the_geom) into new_line FROM snapL2toL1;

	RETURN new_line;     

EXCEPTION
WHEN others THEN
            RAISE EXCEPTION 'geoSICOB (sicob_snap_line2line): % (%) | line_a: % | line_b: %', SQLERRM, SQLSTATE, st_astext(line_a), st_astext(line_b);	
END;
$function$
 