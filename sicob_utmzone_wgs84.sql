SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_utmzone_wgs84(geometry)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
geomgeog geometry;
zone int;
pref int;
BEGIN
--DEVUELVE EL CODIGO CORRESPONDIENTE A LA PROYECCION UTM DE LA GEOMETRIA DADA EN PROYECCION GEOGRAFICA
------------------------------------------------------------------------------------------------------ 
geomgeog:=ST_Transform(ST_Centroid($1),4326);
IF (ST_Y(geomgeog))>0 THEN
pref:=32600;
ELSE
pref:=32700;
END IF;
zone:=floor((ST_X(geomgeog)+180)/6)+1;
RETURN zone+pref;
END;
$function$
 