SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_dissolve(_opt json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE 
  a TEXT;
  _fldgroup text;
  _fldgeom text;
  _condition_a text;
  _subfixresult text;
  _schema text;
  _lyrsql text;

---------------------------------
  sql text;
  lyr_diss text;

 tbl_nameA text; oidA text; sch_nameA text;
 _out json := '{}';
 -------------------------------

BEGIN
---------------------------
--PRE - CONDICIONES
---------------------------
--> Los elementos de las capas de entradas deben ser poligonos (POLYGON).
---------------------------
--PARAMETROS DE ENTRADA
---------------------------
--> a : capa de poligonos que se desea disolver.
--> condition_a (opcional): Filtro para los datos de "a". Si no se especifica, se toman todos los registros.
--> subfix (opcional): texto adicional que se agrega al nombre de la capa resultante.
--> schema (opcional): esquema del la BD donde se desea crear la capa resultante. Si no se especifica se crea en "temp".
--> temp (opcional true/false): Indica si la capa resultante sera temporal mientras dura la transaccion. Esto se requiere cuando el resultado es utilizado como capa intermedia en otros procesos dentro de la misma transaccion. Por defecto es FALSE.
---------------------------
--VALORES DEVUELTOS
---------------------------
--> lyr_diss : capa resultante. Solo se incluyen los campos: sicob_id/fldgroup, the_geom/fldgeom.

--_opt := '{"a":"processed.f20171005fgcbdae84fb9ea1_nsi","b":"coberturas.parcelas_tituladas","subfix":"", "schema":"temp"}';

--_opt := '{"a" : "temp.f20170718fagebdcf580ac83_nsi_tit_tioc_adjust", "b" : "coberturas.predios_proceso_geosicob_geo_201607", "condition_b" : "TRUE", "schema" : "temp", "filter_overlap" : true}';
--_opt := '{"a" : "processed.f20181128dfgbceacd93dce9_fixt", "b" : "coberturas.pop_uso_vigente", "condition_b" : "TRUE", "schema" : "temp", "temp" : false, "filter_overlap" : false, "add_sup_total" : true, "min_sup" : 0, "add_geoinfo" : false}';

--RAISE NOTICE '_opt: %', _opt::text;

a := (_opt->>'lyr_in')::TEXT;
_lyrsql := COALESCE(_opt->>'lyr_sql',''); 
_condition_a := COALESCE((_opt->>'condition')::text, 'TRUE');

_subfixresult := COALESCE(_opt->>'subfix','diss'); 
_schema := COALESCE(_opt->>'schema','temp');

_fldgroup := COALESCE(_opt->>'fldgroup','');
_fldgeom := COALESCE(_opt->>'fldgeom','the_geom');

IF _lyrsql = '' THEN
	SELECT *,a::regclass::oid FROM sicob_split_table_name(a::text) INTO sch_nameA, tbl_nameA, oidA ;
ELSE
	tbl_nameA := a;
    a := '(' || _lyrsql || ') a ';
END IF;
            sql := '
            WITH
            grouppolygons AS (
                SELECT
                    ' || 
                    CASE WHEN _fldgroup <> '' THEN 
                    	_fldgroup
                    ELSE
                    	'1'
                    END || ' as idgroup,
                    st_multi(
                        st_collect(
                            ' || _fldgeom || '                
                        )
                    )
                    AS the_geom
                FROM
                    ' || a || '
                GROUP BY idgroup
            ),
            buff AS (
                SELECT 
                    idgroup,
                    st_buffer(
                        the_geom,
                        5::float / 111000, ''join=mitre mitre_limit=5.0''
                    ) as the_geom
                FROM 
                    grouppolygons
            ),
            dissolve_area AS (
                SELECT 
                    idgroup, st_union(the_geom) AS the_geom
                FROM (
                    SELECT
                      idgroup,
                      st_buffer(
                          st_makepolygon(
                              st_exteriorring(
                                  (st_dump(the_geom)).geom
                              )
                          ),
                          -5::float / 111000, ''join=mitre mitre_limit=5.0''
                      ) as the_geom
                    FROM  buff
                ) t
                GROUP BY idgroup 
            )
            SELECT
            	idgroup AS ' || CASE WHEN _fldgroup <> '' THEN _fldgroup ELSE 'sicob_id' END || ',
                the_geom AS ' || _fldgeom || '
            FROM dissolve_area;';    

    lyr_diss := tbl_nameA || '_' || _subfixresult;
	IF COALESCE((_opt->>'temp')::boolean, FALSE) THEN
    	EXECUTE 'DROP TABLE IF EXISTS ' || lyr_diss;
    	EXECUTE 'CREATE TEMPORARY TABLE ' || lyr_diss || ' ON COMMIT DROP AS ' || sql;
    ELSE
    	lyr_diss := _schema || '.' || lyr_diss;
        EXECUTE 'DROP TABLE IF EXISTS ' || lyr_diss;
    	EXECUTE 'CREATE UNLOGGED TABLE ' || lyr_diss || ' AS ' || sql;
    END IF;
    
    _out := jsonb_build_object('lyr_diss',lyr_diss);
   
    RETURN _out;
    

EXCEPTION
WHEN others THEN
            RAISE EXCEPTION 'geoSICOB (sicob_dissolve) % , % , _opt: % | sql: % ', SQLERRM, SQLSTATE, _opt, sql;	
END;
$function$
 