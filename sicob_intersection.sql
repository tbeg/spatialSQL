CREATE OR REPLACE FUNCTION public.sicob_intersection(param_geoms geometry[])
 RETURNS geometry
 LANGUAGE plpgsql
AS $function$
DECLARE result geometry := param_geoms[1];
BEGIN
-- an intersection with an empty geometry is an empty geometry
  IF array_upper(param_geoms,1) > 1 AND NOT ST_IsEmpty(param_geoms[1]) THEN
    FOR i IN 2 .. array_upper(param_geoms, 1) LOOP
      result := ST_Intersection(result,st_buffer(param_geoms[i],0.0000000000001 ));
      IF ST_IsEmpty(result) THEN
        EXIT;
      END IF;
    END LOOP;
  END IF;
  RETURN result;
END;
$function$
;CREATE OR REPLACE FUNCTION public.sicob_intersection(geom1 geometry, geom2 geometry, geom_type text)
 RETURNS geometry
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE 
  intersected geometry;
  sql text;
  intersected_type text;
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

 SELECT ST_Intersection(geom1,geom2) INTO intersected;

 SELECT geometrytype(intersected) INTO intersected_type;

 if intersected_type = 'GEOMETRYCOLLECTION' then
  select ST_CollectionExtract(intersected,geom_code) INTO intersected;
  SELECT geometrytype(intersected) INTO intersected_type;
 end if;

 IF intersected_type in (geom_type,alternate_type) then
  return intersected;
 else
  return null;
 end if;

end
$function$