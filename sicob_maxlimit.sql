SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_maxlimit(_v double precision, _limit double precision)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
BEGIN
	IF _v > _limit THEN        	
       RETURN _limit;
    ELSE
    	RETURN _v;
    END IF;
END;
$function$
 