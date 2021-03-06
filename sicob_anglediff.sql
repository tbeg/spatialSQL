SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_anglediff(l1 geometry, l2 geometry)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
DECLARE angle1 FLOAT;
DECLARE angle2 FLOAT;
DECLARE dotProduct FLOAT;
BEGIN  
	IF ST_Azimuth(ST_StartPoint(l1), ST_EndPoint(l1)) < ST_Azimuth(ST_EndPoint(l1), ST_StartPoint(l1)) THEN
    	angle1 := ST_Azimuth(ST_StartPoint(l1), ST_EndPoint(l1));
    ELSE
    	angle1 := ST_Azimuth(ST_EndPoint(l1), ST_StartPoint(l1));
    END IF;
    
	IF ST_Azimuth(ST_StartPoint(l2), ST_EndPoint(l2)) < ST_Azimuth(ST_EndPoint(l2), ST_StartPoint(l2)) THEN
    	angle2 := ST_Azimuth(ST_StartPoint(l2), ST_EndPoint(l2));
    ELSE
    	angle2 := ST_Azimuth(ST_EndPoint(l2), ST_StartPoint(l2));
    END IF;
    
    IF angle2 > angle1 THEN
    	RETURN degrees(angle2-angle1);
    ELSE
    	RETURN degrees(angle1-angle2);
    END IF;
/*             
  SELECT ST_Azimuth(ST_StartPoint(l1), ST_EndPoint(l1)) into angle1;
  SELECT ST_Azimuth(ST_StartPoint(l2), ST_EndPoint(l2)) into angle2;  

  select (cos(angle1) * cos(angle2) + sin(angle1) * sin(angle2)) into dotProduct;  

  if dotProduct > 1 then return 0;
  elseif dotProduct < -1 then return 180;
  else return degrees(acos(dotProduct));
  end if;
*/
END;
$function$
 