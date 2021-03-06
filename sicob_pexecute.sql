SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_pexecute(opt json)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
	conn text;
    watcherconn text;
    sql text;
    result text;
    out json := '{}'; 
BEGIN
	sql := COALESCE((opt->>'sql')::text,'');
	conn := sicob_dblink_connect('');
	--> send the query asynchronously using the dblink connection
	--> check for errors dispatching the query
	IF dblink_send_query(conn, sql) = 0 THEN
        out := json_build_object('error', dblink_error_message(conn) );
        result := dblink_disconnect(conn);
        --> Send error to error clallback function 
        IF COALESCE((opt->>'error')::text,'') <> '' THEN
          sql := Format('SELECT %s(%s::json);',(opt->>'error')::text, QUOTE_LITERAL(out::text));
          RAISE DEBUG 'Running %', sql;
          EXECUTE sql;
        END IF;		
        RETURN;
	END IF; 
    
    watcherconn := sicob_dblink_connect('');
    opt := opt::jsonb || jsonb_build_object(
    		'conn', conn,
    		'watcherconn',watcherconn
			);     
    sql := Format('SELECT sicob_presult(%s::json)', QUOTE_LITERAL(opt::text) );
	--> send the query asynchronously using the dblink connection
	--> check for errors dispatching the query
	IF dblink_send_query(watcherconn, sql) = 0 THEN
        out := json_build_object('error', dblink_error_message(conn) );
        PERFORM dblink_disconnect(watcherconn);
        PERFORM dblink_disconnect(conn);
        --> Send error to error clallback function 
        IF COALESCE((opt->>'error')::text,'') <> '' THEN
          sql := Format('SELECT %s(%s);',(opt->>'error')::text, QUOTE_LITERAL(out::text));
          RAISE DEBUG 'Running %', sql;
          EXECUTE sql;
        END IF;	       	
        RETURN;
	END IF;
	   
EXCEPTION
	WHEN others THEN
    	RAISE EXCEPTION 'geoVision [sicob_pexecute], opt: %, % (%)', opt, SQLERRM, SQLSTATE;
END;
$function$
 