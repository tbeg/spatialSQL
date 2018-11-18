CREATE OR REPLACE FUNCTION public.sicob_sliverremover(geometry)
 RETURNS geometry
 LANGUAGE sql
 STRICT
AS $function$
SELECT 
  st_buffer( 
    	st_buffer( st_buildarea($1) ,-0.0000000000001,'endcap=flat join=bevel'),
    	0.0000000000001,'endcap=flat join=bevel'
 ) as the_geom;
$function$
 