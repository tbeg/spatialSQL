CREATE OR REPLACE FUNCTION public.sicob_doors(_edge geometry, _tolerance double precision)
 RETURNS geometry
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE 
    _buffer2snap geometry;
    _sql text;
    _newedge geometry;
    row_cnt integer;
BEGIN
	WITH
	dp_lines AS (
		SELECT st_dump( st_union(_edge) ) as dp 
	),
	pts AS ( 
		SELECT id, (dmp).path[1] As vert,
			(dmp).geom as the_geom
		FROM
 			( SELECT (dp).path[1] As id, st_dumppoints( (dp).geom ) as dmp FROM dp_lines )_lines 
	),
	segments AS (
		SELECT a.id, (ST_MakeLine(ARRAY[a.the_geom, b.the_geom])) AS the_geom, 
    		a.vert as verta, b.vert as vertb
		FROM pts a, pts b 
		WHERE a.id = b.id AND a.vert = b.vert-1 AND b.vert > 1
	),
	vertex AS (
		SELECT id, vert, the_geom,
		(SELECT count(id) FROM segments WHERE  st_intersects(the_geom, st_buffer(pts.the_geom, 0.0000000000001) ) ) as cntseg
		FROM pts
	),
	vertex_dangle AS (
		SELECT * FROM vertex
		WHERE cntseg = 1
	),
    doors AS (
		SELECT a.id as id1,a.the_geom as p1, b.id as id2, b.the_geom p2,
			ST_MakeLine(a.the_geom,b.the_geom) as the_geom 
		FROM vertex_dangle a, vertex_dangle b
		WHERE ST_Azimuth(a.the_geom,b.the_geom) > ST_Azimuth(b.the_geom,a.the_geom)
		and ST_Distance(a.the_geom,b.the_geom) <= _tolerance
	)
    SELECT st_union(the_geom) into _newedge 
    FROM doors;	

	RETURN _newedge;     
EXCEPTION
  WHEN others THEN
              RAISE EXCEPTION
                'geoSICOB (sicob_doors): % (%) | _edge: % | _tolerance: %',
                SQLERRM, SQLSTATE, st_astext(_edge), _tolerance::text;	

END;
$function$
 