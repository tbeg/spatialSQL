CREATE OR REPLACE FUNCTION public.sicob_spike_analyzer(geom geometry, testbuffer double precision, spikeindex double precision)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
AS $function$
-->fuente: https://trac.osgeo.org/postgis/wiki/UsersWikiExamplesSpikeAnalyzer
select case when st_geometrytype($1) in ('ST_Polygon', 'ST_MultiPolygon') then
	(select case when 
		(select max(index) from
			(select (case when (st_perimeter(geom) > 0 and st_area(geom) > 0 and st_perimeter(st_buffer(geom, $2)) > 0)
				then st_area(st_buffer(geom, $2)) / st_area(geom) / (st_perimeter(st_buffer(geom, $2))/st_perimeter(geom))
				else 0
			end) as index from
				(
					select (st_dumprings($1)).geom
				) as sub
			) as max
		) > $3
		then true 
		else false 
	end)
	else false 
end;
$function$
 