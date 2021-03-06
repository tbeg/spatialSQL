CREATE OR REPLACE FUNCTION public.sicob_fix_line_overlap_old(linea geometry)
 RETURNS geometry
 LANGUAGE plpgsql
AS $function$
DECLARE 
 p_ant geometry; p_post geometry;
 linea_ok geometry;
BEGIN

    linea_ok := linea;
    
  --  linea_ok := st_geomfromewkt('LINESTRING(-66.0488439383312 -15.1902147481785,-66.1563562835757 -15.0649863494942,-66.1563252015007 -15.0650225601159)');
    
	IF ST_NPoints(linea_ok) < 3 THEN
		RETURN linea_ok;
	END IF;
	
    p_ant := ST_PointN(linea_ok,2);
    p_post := ST_PointN(linea_ok,3);
    IF ST_Intersects (  st_buffer( st_startpoint(linea_ok), 0.0000001 ),st_makeline(p_ant,p_post)) THEN
    	--si se solapa el punto a la linea
    	linea_ok := ST_RemovePoint(linea_ok, 0); --eliminando el punto inicial 
    END IF;

	IF ST_NPoints(linea_ok) < 3 THEN
		RETURN linea_ok;
	END IF;
	
    p_ant := ST_PointN(linea_ok,ST_NPoints(linea_ok) - 1);
    p_post := ST_PointN(linea_ok,ST_NPoints(linea_ok) - 2);
    IF ST_Intersects ( st_buffer( st_endpoint(linea_ok), 0.000001 )  ,st_makeline(p_ant,p_post)) THEN
    	--si se solapa el punto a la linea
    	RETURN ST_RemovePoint(linea_ok, ST_NPoints(linea_ok) - 1); --eliminando el punto final 
    END IF;
    
	RETURN linea_ok;        

EXCEPTION
WHEN others THEN
            RAISE EXCEPTION 'geoSICOB (sicob_fix_line_overlap): % (%)', SQLERRM, SQLSTATE;	
END;
$function$
 