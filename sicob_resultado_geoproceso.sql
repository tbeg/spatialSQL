SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_resultado_geoproceso(_info json)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	_exec_point varchar;
	_msg varchar;
	_idgeoproceso varchar;
	_sql varchar;
	_exec_error varchar;
BEGIN
	_idgeoproceso := COALESCE((_info->>'idgeoproceso')::text,'-1');
	_exec_point := COALESCE(_info->>'exec_point','inicio');
	_msg := COALESCE(_info->>'msg','{}');

/*        
  PERFORM dblink_connect('autonom_connection', 'dbname=geodatabase user=admderechos password=Abt2016!'); 
*/  
	_sql := 'UPDATE registro_derecho.geoprocesamiento ' || 
    		'SET salida = ''' || _msg || ''', ' || _exec_point || '=''' || clock_timestamp()::text || ''' WHERE registro_derecho.geoprocesamiento.idgeoproceso = ' || _idgeoproceso;
/*
  PERFORM dblink_exec('autonom_connection', _sql, false);
  _exec_error := dblink_error_message('autonom_connection');
*/
	RAISE DEBUG 'Running %', _sql;
    EXECUTE _sql;
/*    
  IF position('ERROR' in _exec_error) > 0 
      OR position('WARNING' in _exec_error) > 0 THEN
    RAISE EXCEPTION 'sicob_resultado_geoproceso: %', _exec_error;
  END IF;


  PERFORM dblink_disconnect('autonom_connection');
*/

EXCEPTION
   WHEN others THEN
  /*   PERFORM dblink_disconnect('autonom_connection');*/
     RAISE EXCEPTION 'sicob_resultado_geoproceso: (% - %)', _sql , SQLERRM;
END;
$function$
 