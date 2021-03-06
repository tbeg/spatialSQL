CREATE OR REPLACE FUNCTION public.sicob_spikeremover1(geometry, angle double precision)
 RETURNS geometry
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
declare
	_out geometry;
    
begin
    if (select st_geometrytype($1)) = 'ST_MultiPolygon' then
    	_out := st_buildarea(  ST_GeomFromText(st_astext($1), 4326));
    else 
        _out := $1;
    end if;
    	
	if st_geometrytype(_out) <> 'ST_Polygon' then
    	RETURN $1;
    end if;       

select st_makepolygon(
        (/*outer ring of polygon*/
        select st_exteriorring(sicob_spikeremovercore(_out,$2)) as outer_ring
          from st_dumprings(_out)where path[1] = 0 
        ),  
		array(/*all inner rings*/
        select st_exteriorring(sicob_spikeremovercore(geom, $2)) as inner_rings
          from st_dumprings(_out) where path[1] > 0) 
) into _out as geom;

/*        
select st_makepolygon(
        (/*outer ring of polygon*/
        select st_exteriorring(sicob_spikeremovercore(_out,$2)) as outer_ring
          from st_dumprings(_out)where path[1] = 0 
        ),  
		array(/*all inner rings*/
        select st_exteriorring(sicob_spikeremovercore(_out, $2)) as inner_rings
          from st_dumprings(_out) where path[1] > 0) 
) into _out as geom;
*/
/*
select st_exteriorring(sicob_spikeremovercore(_out,$2)) into _out as outer_ring
          from st_dumprings(_out)where path[1] = 0 ;
*/
/*
select st_exteriorring(sicob_spikeremovercore(geom, $2)) into _out as inner_rings
          from st_dumprings(_out) where path[1] > 0 ;
*/

RETURN _out;

EXCEPTION
WHEN others THEN
            RAISE EXCEPTION 'geoSICOB-> % (sicob_spikeremover): % (%)',st_astext(_out), SQLERRM, SQLSTATE;	
end;
$function$
 