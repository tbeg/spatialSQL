SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_notify_geoprocess_end()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE 
 msg text;
BEGIN
    msg := COALESCE(NEW.salida,'{}');
    IF msg = '{}'::text THEN
    	-- Result is ignored since this is an AFTER trigger
    	RETURN NULL;
    END IF;
    
    IF length(msg) > 7999 THEN --> El limite maximo del mensaje son 8000 caracteres.
    	msg := '{"outlimit":true,"idgeoproceso":' || NEW.idgeoproceso::text || '}'; 
    END IF;
    
    -- Execute pg_notify(channel, notification)
    PERFORM pg_notify('task_' || NEW.idgeoproceso::text ,msg);
    PERFORM pg_notify('task_all' ,msg);

    
    RETURN NULL;

	EXCEPTION
	WHEN others THEN      
        RAISE EXCEPTION 'sicob_notify_geoprocess_end : %', SQLERRM;
END;
$function$
 