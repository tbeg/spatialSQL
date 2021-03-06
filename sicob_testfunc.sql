SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_testfunc()
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    sql text;
    db text;
    username text;
    connectstring text;
    conn text;
    r record;
    condition text;
    dispatch_result integer;
    dispatch_error text;
    n integer;
    num_done integer;
    status integer;
    processes jsonb[];
    result jsonb;
    results jsonb = '[]';
BEGIN
	SELECT current_database(),CURRENT_USER INTO db,username;
	connectstring := QUOTE_LITERAL('password=Abt2016! dbname=' || db || ' user=' || username);
	RAISE NOTICE '%', connectstring;
    
  -- loop through chunks
  FOR r IN   
	SELECT *  FROM sicob_chunk_info('{"lyr_in":"processed.f20170718fagebdcf580ac83_nsi","num_chunks":"3"}')
	LOOP
    	conn := 'p_' || r.chunk_id; 
        condition := '(a.sicob_id ' || CASE WHEN r.chunk_id = 1 OR r.start_id = r.end_id THEN '>=' ELSE '>' END || ' ' || r.start_id || ' AND a.sicob_id <= ' || r.end_id ||  ')';
        
        sql := 'SELECT dblink_connect(' || QUOTE_LITERAL(conn) || ',' || connectstring || ');';
        EXECUTE sql;
        SELECT array_append(processes, jsonb_build_object('processid', conn::text,'condition', condition::text ) ) INTO processes;
        
        sql := '
        SELECT sicob_obtener_predio(''{"lyr_in":"processed.f20171005fgcbdae84fb9ea1_nsi","condition":"' || condition || '","subfix":"_p' || r.chunk_id || '"}'')
        ';
        
        sql := '
        SELECT sicob_overlap(''{"a":"processed.f20171005fgcbdae84fb9ea1_nsi","b":"coberturas.parcelas_tituladas","schema":"temp","temp":false,"add_diff":true,"tolerance":"5.3","condition_a":"' || condition || '","subfix":"_p' || r.chunk_id || '_tit"}'')
        ';

        sql := '
        SELECT sicob_obtener_predio(''{"lyr_in":"processed.f20170718fagebdcf580ac83_nsi","condition":"' || condition || '","subfix":"_p' || r.chunk_id || '","tolerance":"5.3"}'')
        ';
        
        --send the query asynchronously using the dblink connection
        sql := 'SELECT dblink_send_query(' || QUOTE_LITERAL(conn) || ',' || QUOTE_LITERAL(sql) || ');';
        EXECUTE sql INTO dispatch_result;

        -- check for errors dispatching the query
        IF dispatch_result = 0 THEN
        sql := 'SELECT dblink_error_message(' || QUOTE_LITERAL(conn)  || ');';
        EXECUTE sql INTO dispatch_error;
            RAISE '%', dispatch_error;
        END IF;
        
	END LOOP;     

	n := 1;
    -- wait until all queries are finished
	LOOP
    	conn := (processes[n]->>'processid')::text;
        sql := 'SELECT dblink_is_busy(' || QUOTE_LITERAL(conn) || ');';
        EXECUTE sql INTO status;
        
        IF status = 0 THEN	        	
            -- check for error messages
        	sql := 'SELECT dblink_error_message(' || QUOTE_LITERAL(conn)  || ');';
        	EXECUTE sql INTO dispatch_error;
        
        	IF dispatch_error <> 'OK' THEN
            	-- show error and finish
          		RAISE '%', dispatch_error;
        	END IF;
            
            --get results
            sql := '
            SELECT * FROM dblink_get_result(' || QUOTE_LITERAL(conn) || ' ) AS t(res jsonb);
            ';
            EXECUTE sql INTO result;
                                  
            result := jsonb_build_object('processid', conn, 'condition', (processes[n]->>'condition')::text, 'result', result);
            RAISE NOTICE 'Completado %', conn;
            
            results := results || jsonb_build_array(result);
            
            --SELECT array_append(results, result::json ) INTO results;            
            
            -- finish process
            sql := 'SELECT dblink_disconnect(' || QUOTE_LITERAL(conn) || ');';
            EXECUTE sql;        	
            SELECT array_remove(processes, processes[n]::jsonb) INTO processes;
                        
            IF n > array_length(processes, 1) THEN
            	n = 1;
            END IF;            
        ELSE
        	IF n = array_length(processes, 1) THEN
            	n := 1;
            ELSE
            	n := n + 1;
            END IF;
      	END if;
        
        IF COALESCE(processes, '{}') = '{}' THEN
      		EXIT;
    	END IF;
	END LOOP;
    
  
  -- wait until all queries are finished
  /*
  LOOP
    num_done := 0;
  
    FOR n IN 1..r.chunk_id
    LOOP
      conn := 'conn_' || n;
      sql := 'SELECT dblink_is_busy(' || QUOTE_LITERAL(conn) || ');';
      EXECUTE sql INTO status;

      IF status = 0 THEN	
        -- check for error messages
        sql := 'SELECT dblink_error_message(' || QUOTE_LITERAL(conn)  || ');';
        EXECUTE sql INTO dispatch_error;
        IF dispatch_error <> 'OK' THEN
          RAISE '%', dispatch_error;
        END IF;

        num_done := num_done + 1;
      END if;
    END LOOP;
  
    IF num_done >= r.chunk_id THEN
      EXIT;
    END IF;
    
  END LOOP;

  -- disconnect the dblinks
  FOR n IN 1..r.chunk_id
  LOOP
    conn := 'conn_' || n;
    sql := 'SELECT dblink_disconnect(' || QUOTE_LITERAL(conn) || ');';
    EXECUTE sql;
  END LOOP;
  */
  
RETURN results;
    
-- error catching to disconnect dblink connections, if error occurs
EXCEPTION WHEN others THEN
  BEGIN
  	--RAISE NOTICE '% %', SQLERRM, SQLSTATE;
    IF array_length(processes, 1) > 0 THEN
      FOREACH result IN ARRAY processes LOOP
          sql := 'SELECT dblink_disconnect(' || QUOTE_LITERAL(result->>'processid') || ');';
          EXECUTE sql;
      END LOOP;
    END IF;
  	RAISE EXCEPTION '% %', SQLERRM, SQLSTATE;
  EXCEPTION WHEN others THEN
    RAISE EXCEPTION '% %', SQLERRM, SQLSTATE;
  END;	
END;
$function$
 