SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_presult(opt json)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	conn text;
    sql text;
    command text;
    timeout int;
    response text;
    pending_count int;
    status int;
    out json := '{}'; 
BEGIN
	pending_count := 1;
    conn := COALESCE((opt->>'conn')::text,'');
    timeout := COALESCE((opt->>'timeout')::int,5);

  LOOP --> Bucle persistente hasta obtener respuesta o agotar tiempo de espera.

      IF timeout = 0  THEN
      	response := 'Tiempo agotado.';
        -- return error and disconnect
        PERFORM dblink_disconnect(conn);
        out := json_build_object('error', response );
        --> Send error to error clallback function 
        IF COALESCE((opt->>'error')::text,'') <> '' THEN
          sql := Format('SELECT %s(%s);',(opt->>'error')::text, QUOTE_LITERAL(out::text));
          RAISE DEBUG 'Running %', sql;
          EXECUTE sql;
        END IF;
        RETURN;
        EXIT;        
      END IF;
      
      command := 'dblink_is_busy(conn)';
      status := dblink_is_busy(conn);
      
      IF status = 0 THEN	--> complete jobs?        	
          -- check for error messages
          response := dblink_error_message(conn);
          IF response <> '' THEN
              -- return error and disconnect
              PERFORM dblink_disconnect(conn);
              out := json_build_object('error', response );
              --> Send error to error clallback function 
              IF COALESCE((opt->>'error')::text,'') <> '' THEN
              	sql := Format('SELECT %s(%s);',(opt->>'error')::text, QUOTE_LITERAL(out::text));
                RAISE DEBUG 'Running %', sql;
                EXECUTE sql;
              END IF;
              RETURN;
          END IF;              


          --get results
			sql := 'SELECT * FROM dblink_get_result(' || QUOTE_LITERAL(conn) || ' ) AS t(res json);';
			EXECUTE sql INTO out;
          -- finish process
          PERFORM dblink_disconnect(conn);
          --> Send out to success clallback function 
          IF COALESCE((opt->>'success')::text,'') <> '' THEN
            sql := Format('SELECT %s(%s);',(opt->>'success')::text, QUOTE_LITERAL(out::text));
            RAISE DEBUG 'Running %', sql;
            EXECUTE sql;
          END IF;
          RETURN; 
          EXIT;         
      ELSE
		PERFORM pg_sleep(1);
        timeout := timeout-1;
      END IF;           
  END LOOP;

EXCEPTION
	WHEN others THEN
    	RAISE EXCEPTION 'geoVision [sicob_presult], opt: %, %, %, %,(%)', opt, sql, command, SQLERRM, SQLSTATE;
END;
$function$
 