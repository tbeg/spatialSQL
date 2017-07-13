CREATE OR REPLACE FUNCTION public.sicob_setpoint(_line geometry, _pos integer, _topnt geometry, _lineref geometry)
 RETURNS geometry
 LANGUAGE plpgsql
 IMMUTABLE STRICT COST 1
AS $function$
DECLARE 
  _i integer;
  _p geometry[];
  _crosspoint geometry;
  new_line geometry;
BEGIN
/*
_line:= st_geomfromtext('
LINESTRING(-65.9829292803582 -14.9999840553936,-65.982929299 -14.99998406,-65.960443313 -14.9350309239999,-65.9604432927493 -14.93503098373)
');
_pos := 0;
_topnt := st_geomfromtext('
POINT(-65.9829830536709 -14.999988553751)
');

_lineref := st_geomfromtext('
LINESTRING(-65.9829830536709 -14.999988553751,-65.941862219 -14.9898364549999,-65.9604596276972 -14.9349795049938)
');
*/

  -- Check geometry type
  if st_geometrytype(_line)<>'ST_LineString' OR st_geometrytype(_lineref)<>'ST_LineString' then
    return null;
  end if;

  if st_crosses(_line, _lineref) THEN
	_crosspoint := ST_Intersection(_line,_lineref);
    if ST_Length(
    	ST_LineSubstring(
        	_line, 
            ST_LineLocatePoint(_line, st_startpoint(_line)), 
            ST_LineLocatePoint(_line, _crosspoint)
        )
       ) 
       > 
		ST_Length(
        	ST_LineSubstring(
            	_line, 
                ST_LineLocatePoint(_line,_crosspoint), 
                ST_LineLocatePoint(_line,st_endpoint(_line))
            )
       )
    THEN
    	_line := ST_LineSubstring(
        	_line, 
            ST_LineLocatePoint(_line, st_startpoint(_line)), 
            ST_LineLocatePoint(_line, _crosspoint)
        );
    ELSE
    	_line := ST_LineSubstring(
            	_line, 
                ST_LineLocatePoint(_line,_crosspoint), 
                ST_LineLocatePoint(_line,st_endpoint(_line))
         );
    END IF;
  END IF;

    IF _pos > st_npoints(_line)-1 THEN
    	_pos := st_npoints(_line)-1;
    END IF;
      
	new_line := st_setpoint(_line,_pos,_topnt); 
    --return new_line;
    --verificar que new_line no se cruce con _lineref
    if st_crosses(new_line, _lineref) THEN
		if(st_equals(_topnt, st_endpoint(_lineref)) ) then
			_lineref := st_reverse(_lineref);
		end if;
		-- Decompose linestring into matrix of points, but checking no same point in sequence
		_p := array[st_pointn(_lineref, 1)];
		for _i in 2..st_npoints(_lineref) loop
			if not st_equals(_p[array_length(_p, 1)], st_pointn(_lineref, _i)) then  
				_p := _p || st_pointn(_lineref, _i);
			end if;
		end loop;        
        _i := 2; -- Ya se movio anteriorrmete el vertice _pos al punto 1 ahora toca moverlo al punto 2
		while _i<=array_length(_p,1) and st_crosses(new_line, _lineref) loop
        	RAISE DEBUG 'new_ine %', st_astext(new_line);
        	new_line := st_setpoint(new_line,_pos,_p[_i]);
            RAISE DEBUG 'new_ine %', st_astext(new_line);
        	_i := _i + 1;
        end loop;       	
    end if;
  
    RAISE DEBUG 'new_ine %', st_astext(new_line);
   
    return new_line;
    
	EXCEPTION
		WHEN others THEN
			RAISE EXCEPTION 'sicob_setpoint: (%, %) | _line:% | _pos:% | _topnt:% | _lineref:%', SQLERRM, SQLSTATE, st_astext(_line), _pos, st_astext(_topnt), st_astext(_lineref);	
END;
$function$
 