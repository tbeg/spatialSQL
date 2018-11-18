CREATE OR REPLACE FUNCTION public.sicob_testfunc()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	_edge geometry;
    _newborde geometry;
    _tolerance float;
    _target regclass;
    _buffer2snap geometry;
    _sql text;
    row_cnt int;
    arrcol  varchar[];
    col varchar;
    s varchar;
BEGIN
s := 'uno,dos,tres,cuatro';
arrcol := string_to_array(s, ',') ;
FOREACH col IN ARRAY arrcol LOOP
    s := replace(s, col, 'b.' || col);
END LOOP;

SELECT ST_ExteriorRing(
		(ST_Dump(the_geom)).geom) into _edge
    FROM  processed.f20160708agfbdecf223329c_nsi  --processed.f20160929daebgcf1933cf73_nsi 
	WHERE sicob_id =2;

_tolerance := 6::float/111000;

_target := 'coberturas.predios_titulados';

	_buffer2snap := st_union(ST_Buffer(_edge,  _tolerance * 2, 'join=bevel'));
 
 --Obteniendo la parte de b que se encuentra dentro de _buffer2snap 
_sql := '
CREATE TEMPORARY TABLE _b_into_2snap ON COMMIT DROP AS
  SELECT idpol_b, row_number() over() as id, (dmp).geom as the_geom
  from(
      SELECT idpol_b, st_dump(the_geom) as dmp  
      FROM (
          SELECT	b.sicob_id as idpol_b,
          CASE 
              WHEN ST_CoveredBy(b.the_geom, $1) 
              THEN b.the_geom 
          ELSE 
              ST_Multi(
                  ST_Intersection($1,b.the_geom)
              ) 
          END AS the_geom 
          FROM ' || _target::text || ' b 
          WHERE ST_Intersects(b.the_geom,$1)  AND NOT ST_Touches(b.the_geom, $1)    
      ) q
  ) p
  ';
 EXECUTE _sql USING _buffer2snap; 

RAISE DEBUG 'Running %', _sql;

	GET DIAGNOSTICS row_cnt = ROW_COUNT;
	IF row_cnt < 1 THEN --si no tiene registros, no existe sobreposicion
		RAISE DEBUG 'Result %' , st_Astext(_edge);
	END IF;
    
DROP TABLE IF EXISTS temp._line_pol_b;
CREATE TABLE temp._line_pol_b AS  
 --Obteniendo las lineas del poligono pol_b dentro de la zona de snapping snapzone
    SELECT idpol_b, row_number() over() as segment, (dp).geom as the_geom, st_startpoint((dp).geom) as pini, st_endpoint((dp).geom) as pfin
    FROM(
        SELECT idpol_b, st_dump(the_geom) as dp  
        FROM (
          SELECT idpol_b, st_intersection(sicob_polygon_to_line((ST_Dump(pol_b.the_geom)).geom), (SELECT st_union(the_geom) from temp._snapzone ) 
          ) as the_geom 
          FROM temp._pol_b pol_b
        ) r
    ) q; 
    

EXCEPTION
WHEN others THEN
            RAISE EXCEPTION ' (%, %)', SQLERRM, SQLSTATE;	
END;
$function$
 