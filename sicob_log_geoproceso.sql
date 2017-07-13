CREATE OR REPLACE FUNCTION public.sicob_log_geoproceso(_info json)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	_exec_point varchar;
	_msg varchar;
    _geojson varchar;
	_idgeoproceso varchar;
	_sql varchar;
BEGIN
---------------------------
--REGISTRA LA INFORMACION INICIAL Y FINAL 
--GENERADA DURANTE LA EJECUCION DE UN PROCESO
---------------------------
--PARAMETROS DE ENTRADA
---------------------------
--> idgeoproceso: Identificador del proceso registrado en la tabla "registro_derecho.geoprocesamiento" 
--> exec_point: Punto de ejecucion ("inicio" o "fin") para el registro cronologico.
--> msg : cadena json con la informacion a registrar en el campo "salida" del geoproceso.
--	      Este json puede incluir un geojson dentro de la variable "lyr_geojson" como parte de "msg",
--		  ese valor es almacendado en el campo "geojson" de la tabla "registro_derecho.geoprocesamiento". 
	_idgeoproceso := COALESCE((_info->>'idgeoproceso')::text,'-1');
	_exec_point := COALESCE(_info->>'exec_point','inicio');
    _geojson := COALESCE(_info->'msg'->>'lyr_geojson','');

    IF _geojson <> '' THEN
    	_msg := (_info->'msg')::jsonb - 'lyr_geojson';
    ELSE
    	_msg := COALESCE(_info->>'msg','{}');
    END IF;
  
	_sql := 'UPDATE registro_derecho.geoprocesamiento ' || 
    		'SET salida = ''' || _msg || ''', ' || _exec_point || '=''' || clock_timestamp()::text || '''';
    IF _geojson <> '' THEN
    	_sql := _sql || ', geojson = ''' || _geojson || '''';
    END IF;        
         
    _sql := _sql || ' WHERE registro_derecho.geoprocesamiento.idgeoproceso = ' || _idgeoproceso;

	RAISE DEBUG 'Running %', _sql;
    EXECUTE _sql;

EXCEPTION
   WHEN others THEN
     RAISE EXCEPTION 'sicob_log_geoproceso: (% - %)', _sql , SQLERRM;
END;
$function$
 