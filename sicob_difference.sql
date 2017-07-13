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
AS $function$
DECLARE 
  difference geometry;
  sql text;
  difference_type text;
  geom_code integer;
  alternate_type text;
BEGIN
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

 SELECT ST_Difference(geom1,geom2) INTO difference;
 SELECT geometrytype(difference) INTO difference_type;
 if difference_type = 'GEOMETRYCOLLECTION' then
  select ST_CollectionExtract(difference,geom_code) INTO difference;
  SELECT geometrytype(difference) INTO difference_type;
 end if;
 if difference_type in (geom_type,alternate_type) then
  return difference;
 else
  return null;
 end if;
END
$function$
 