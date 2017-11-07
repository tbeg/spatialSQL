CREATE OR REPLACE FUNCTION public.sicob_difference(geometry, geometry)
 RETURNS geometry
 LANGUAGE plpgsql
AS $function$
DECLARE g geometry;
BEGIN
	g :=  ST_Union(COALESCE(ST_Difference($1, $2), $1)) ;
	RETURN g;
END;
$function$
;CREATE OR REPLACE FUNCTION public.sicob_difference(geom1 geometry, geom2 geometry, geom_type text)
 RETURNS geometry
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE 
  diff geometry;
  exterior_ring geometry;
  sql text;
  diff_type text;
  geom_code integer;
  alternate_type text;
BEGIN
/*
 geom1 := 'MULTIPOLYGON(((-60.417921278527 -16.8530883325313,-60.4189945220582 -16.8544373819229,-60.4194515960511 -16.8544771738476,-60.4205026544912 -16.8545686731075,-60.4207894910172 -16.854004721193,-60.4207323211207 -16.8536455434266,-60.4203915579186 -16.8536113858879,-60.4198671330623 -16.8533956888677,-60.419839764618 -16.8531265006331,-60.4198144222014 -16.8527079801542,-60.4196352196733 -16.8521979093471,-60.4190165384765 -16.8520706385492,-60.4182371079817 -16.8523595438002,-60.417956004815 -16.8530082007488,-60.417921278527 -16.8530883325313)))'::geometry;
 geom2 := 'POLYGON((-60.4189954804597 -16.8544374653594,-60.4194515960511 -16.8544771738476,-60.4205026544912 -16.8545686731075,-60.4207894910172 -16.854004721193,-60.4207323211207 -16.8536455434266,-60.4203915579186 -16.8536113858879,-60.4198671330623 -16.8533956888677,-60.419839764618 -16.8531265006331,-60.4198144222014 -16.8527079801542,-60.4196352196733 -16.8521979093471,-60.4190165384765 -16.8520706385492,-60.4182371079817 -16.8523595438002,-60.417956004815 -16.8530082007488,-60.4179215281215 -16.8530877565857,-60.4189954804597 -16.8544374653594))'::geometry;
 geom_type := 'POLYGON';
 */

IF st_isvalid(geom1) = FALSE THEN
	SELECT st_makevalid(geom1) INTO geom1;
END IF;

 if geom_type = 'POINT' THEN
  geom_code := 1;
  alternate_type := 'MULTIPOINT';
 elsif geom_type = 'LINESTRING' THEN
  geom_code := 2;
  alternate_type := 'MULTILINESTRING';
 elsif geom_type = 'POLYGON' THEN
  geom_code := 3;
  alternate_type := 'MULTIPOLYGON';
 else
  raise 'geom_type must be one of POLYGON, LINESTRING, or POINT';
 end if;

--> CONVIRTIENDO GEOMETRYCOLLECTION
 SELECT geometrytype(geom2) INTO diff_type;
 IF diff_type = 'GEOMETRYCOLLECTION' then
 	SELECT st_makevalid(ST_CollectionExtract(geom2,geom_code)) INTO geom2;
 end if;
 IF diff_type = 'MULTIPOLYGON' AND st_isvalid(geom2)=FALSE THEN
 	SELECT st_makevalid(geom2) INTO geom2;
 end if;

/*
SELECT st_union(t.the_geom) 
FROM (
	SELECT st_exteriorring(the_geom) as the_geom
    FROM (
    	SELECT (st_dump(geom1)).geom as the_geom
    ) u
) t INTO exterior_ring;
 */
 
--SELECT  st_exteriorring(geom1) INTO exterior_ring;


SELECT  ST_Collect(ST_ExteriorRing(the_geom))  INTO  exterior_ring
	FROM (
        SELECT (dp).path[1] as gid, (dp).geom as the_geom 
        FROM(
            SELECT st_dump(geom1) as dp
            ) t        
    ) As u
GROUP BY gid;
 
 SELECT   ST_Difference( ST_Difference(geom1,geom2),  st_buffer( exterior_ring,0.000000001,'join=mitre') ) INTO diff;


SELECT
st_snap(
	diff,
	exterior_ring,
    0.00000000001
) INTO diff;


 --SELECT ST_Difference(geom1,geom2) INTO diff;
 
 SELECT geometrytype(diff) INTO diff_type;
 
 if diff_type = 'GEOMETRYCOLLECTION' then
  select ST_CollectionExtract(diff,geom_code) INTO diff;
  SELECT geometrytype(diff) INTO diff_type;
 end if;

 IF diff_type in (geom_type,alternate_type) then	
  return diff;
 else
  return null;
 end if;
 
EXCEPTION
WHEN others THEN
	RAISE EXCEPTION 'geoSICOB (sicob_difference)-> geom1:% | geom2:% | geom_type:% >> % (%), diff --> %, SQL --> %', st_astext(geom1) , st_astext(geom2),  geom_type,  SQLERRM, SQLSTATE, st_astext(diff), sql;	
            
end;
$function$
 