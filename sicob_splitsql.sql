SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_splitsql(_query text, _opt json)
 RETURNS text[]
 LANGUAGE plpgsql
AS $function$
DECLARE

    _key text;

    _table_to_chunk text;

    _filter text;

    _txt_chunk_condition text;

    _txt_chunk_id text;

    _partitions int;

    

    sql text;



    r record;

    condition text;

    listSQL text[];



BEGIN

---------------------------

--PARAMETROS DE ENTRADA

---------------------------

--> query: Consulta SQL para ser particionada. Debe incluir en su texto para la 

--	sentencia WHERE la cadena a ser reemplazadas por la condicion logica que 

--	separa el bloque que por defecto es "<chunk_condition>" y si es necesario 

--	incluir la cadena de identificacion del bloque <chunk_id> donde se requiera 

--	diferenciar cada consulta. Por ejemplo:

--	'SELECT sicob_obtener_predio(''{"lyr_in":"processed.f20170718fagebdcf580ac83_nsi",

--	"condition":"<chunk_condition>","subfix":"_p<chunk_id>","tolerance":"5.3"}'')'

--> _opt: JSON conteniendo los siguientes parametros de opciones:

--		- table_to_chunk: Nombre de la tabla referenciada en la consulta de "query"

--		 sobre la cual se aplicara el criterio de particion.

--		- filter (opcional): CondiciÃ³n preestablecida para incluir el WHERE de la

--		 tabla a ser particionada.

--		- partitions: cantidad de bloques en la que se divide la tabla a particionar.

--		- txt_chunk_condition (opcional): Cadena a ser reemplazadas por la condicion

--		 logica que separa el bloque. Por defecto es "<chunk_condition>".

--		- txt_chunk_id (opcional): Cadena a ser reemplazada con el identificador

--		 del bloque. Por defecto es "<chunk_id>".

 

---------------------------

--VALORES DEVUELTOS

---------------------------

-- Devuelve un array de texto conteniendo las consultas SQL resultantes de la 

-- particion.





	--_query := 'SELECT sicob_obtener_predio(''{"lyr_in":"processed.f20170718fagebdcf580ac83_nsi","condition":"<chunk_condition>","subfix":"_p<chunk_id>","tolerance":"5.3"}'')';   

    --_opt := '{"table_to_chunk":"processed.f20170718fagebdcf580ac83_nsi", "partitions":"10"}'::json;

    

	_table_to_chunk := COALESCE( (_opt->>'table_to_chunk')::text, '');
    
    
    IF _table_to_chunk = '' THEN
    	SELECT array_append(listSQL, _query::text) INTO listSQL; 
        RETURN listSQL;   
    END IF;
    

    _key := COALESCE( (_opt->>'key')::text, 'sicob_id');

    _filter := COALESCE( (_opt->>'filter')::text, 'TRUE');

    _txt_chunk_condition := COALESCE( (_opt->>'txt_chunk_condition')::text, '<chunk_condition>');

    _txt_chunk_id := COALESCE( (_opt->>'txt_chunk_id')::text, '<chunk_id>');

    _partitions := COALESCE( (_opt->>'partitions')::int, 1);

     

  -- loop through chunks

  FOR r IN   

	SELECT *  FROM sicob_chunk_info(('{"lyr_in":"' || _table_to_chunk || '","condition":"' || _filter || '","num_chunks":"' || _partitions::text || '"}')::json)

	LOOP

        condition := _filter || ' AND (a.sicob_id ' || CASE WHEN r.chunk_id = 1 OR r.start_id = r.end_id THEN '>=' ELSE '>=' END || ' ' || r.start_id || ' AND a.sicob_id <= ' || r.end_id ||  ')';

               

        SELECT 

	REPLACE(

    	REPLACE(

        	_query::text, 

            _txt_chunk_condition::text, 

            condition::text

        ),

        _txt_chunk_id::text,

        r.chunk_id::text

    ) as ready_query INTO sql;

               

        SELECT array_append(listSQL, sql::text) INTO listSQL;

        

	END LOOP;     

  

	RETURN listSQL;

    

-- error catching to disconnect dblink connections, if error occurs

EXCEPTION WHEN others THEN

    RAISE EXCEPTION 'sicob_splitSQL: % (%)', SQLERRM, SQLSTATE;

	

END;
$function$
 