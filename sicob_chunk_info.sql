SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_chunk_info(_opt json)
 RETURNS TABLE(chunk_id integer, start_id integer, end_id integer)
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
DECLARE
	_num_chunks integer;
    _condition text;
    sql text;
BEGIN
--PARAMETROS EN VARIABLE _opt
  -->lyr_in, <-- capa PostGIS con los elementos geometricos
  -->condition TEXT  <-- (opcional) condicion para el filtro WHERE
  -->num_chunks <-- Candidad de partes iguales en que se dividiran los registros.

--_opt := '{"lyr_in":"processed.f20170718fagebdcf580ac83_nsi", "num_chunks":"10" }';

	_num_chunks := COALESCE( (_opt->>'num_chunks')::integer, 1);
    _condition := COALESCE( (_opt->>'condition')::text, 'TRUE');
    
 sql := '
 WITH 
  table_to_chunk AS (
    SELECT row_number() OVER () as ___o, sicob_id 
    FROM  (
      SELECT sicob_id 
      FROM 
      ' || (_opt->>'lyr_in')::text || ' a
      WHERE TRUE AND ' || _condition || '
      order by sicob_id
    ) r
  ),
  params AS (
  SELECT 1 as min_id, max(___o) as max_id, 
  ( max(___o)-1) / (  CASE WHEN max(___o) > ' || _num_chunks || ' THEN ' || _num_chunks || ' ELSE max(___o) END ) + 1  as step_size, 
  CASE WHEN max(___o) > ' || _num_chunks || ' THEN ' || _num_chunks || ' ELSE max(___o) END as num_chunks 
  FROM table_to_chunk
  ),
  partition_chunk AS (
    SELECT DISTINCT ON(lbnd) * 
    FROM (
      SELECT  
      generate_series(1, (SELECT num_chunks FROM params) ) as i,
      generate_series( (SELECT min_id FROM params) , (SELECT max_id FROM params) , (SELECT step_size FROM params) ) as lbnd, 
      generate_series(
          (SELECT min_id FROM params) + (SELECT step_size FROM params) - 1, 
          (SELECT max_id FROM params) + (SELECT step_size FROM params) , 
          (SELECT step_size FROM params) 
      ) as ubnd           
      limit (SELECT num_chunks FROM params)
	) t
  )
  SELECT 
  	p.i::int as chunk_id, 
  	(SELECT sicob_id FROM table_to_chunk WHERE ___o = p.lbnd) as start_id, 
  	COALESCE((SELECT sicob_id FROM table_to_chunk WHERE ___o = p.ubnd), (SELECT max(sicob_id) FROM table_to_chunk )  ) as end_id
  FROM partition_chunk p';
	RETURN QUERY EXECUTE sql;
    
	EXCEPTION
	WHEN others THEN
            RAISE EXCEPTION 'geoSICOB (sicob_chunk_info) error:(%,%); _opt:%, sql:% ',  SQLERRM,SQLSTATE, _opt::text, sql;	
END;
$function$
 