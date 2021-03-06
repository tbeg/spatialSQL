SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_shadowline_old(_edge geometry, _line geometry)
 RETURNS geometry
 LANGUAGE plpgsql
AS $function$
DECLARE
 new_line geometry;

BEGIN

/*
SELECT   
  sicob_fix_line_overlap( st_reverse(sicob_fix_line_overlap( st_makeline(t.the_geom) ))) into new_line 
FROM (
	SELECT
		vert,
		ST_ClosestPoint(
				_edge,
				ptob.the_geom
		) as the_geom
	FROM (
		SELECT row_number() over () as vert,
			(dmp).geom as the_geom
		FROM
 			(SELECT st_dumppoints(_line) as dmp) dp
	) ptob
 ) t;

RETURN sicob_st_linesubstring(
_edge,
st_startpoint(new_line),
st_endpoint(new_line),
st_lineinterpolatepoint(new_line, 0.5)
);
*/


WITH 

pts AS ( 
	SELECT row_number() over () as vert,
			(dmp).geom as the_geom
	FROM
 		(SELECT st_dumppoints( _line ) as dmp) dp
),
segments AS (
	SELECT 
    (ST_MakeLine(ARRAY[a.the_geom, b.the_geom])) AS the_geom,

    (ST_MakeLine(ARRAY[
    	ST_ClosestPoint(
			_edge,
			a.the_geom
		),
    	ST_ClosestPoint(
			_edge,
			b.the_geom
		)
    ])) 

    as linear_shadow,
    a.vert as segment_id
    FROM pts a, pts b 
    WHERE  a.vert = b.vert-1 AND b.vert > 1
),
shadows AS (
	SELECT segment_id, 
		sicob_st_linesubstring(
			_edge,
			st_startpoint(linear_shadow),
			st_endpoint(linear_shadow),
			st_lineinterpolatepoint(linear_shadow, 0.5)
		) as shadow
	FROM segments
    WHERE 
    st_equals( st_startpoint(linear_shadow), st_endpoint(linear_shadow) ) = FALSE
)
SELECT  st_linemerge( ST_Collect(shadow) )  into new_line FROM shadows;

RETURN new_line;


EXCEPTION
WHEN others THEN
            RAISE EXCEPTION 'geoSICOB (sicob_shadowline): % (%)',  SQLERRM, SQLSTATE;	
END;
$function$
 