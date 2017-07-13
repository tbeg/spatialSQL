CREATE OR REPLACE FUNCTION public.sicob_ungroup_ubication(reloid text)
 RETURNS TABLE(sicob_id integer, nom_mun text, nom_prov text, nom_dep text)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY EXECUTE 'SELECT DISTINCT
        p.sicob_id as sicob_id,  m.nom_mun::text, m.nom_prov::text, m.nom_dep::text
        FROM 
        coberturas.limites_municipales as m 
           INNER JOIN ' || reloid::text || '  as p
            ON (ST_CoveredBy(p.the_geom, m.the_geom) OR ST_Intersects(p.the_geom, m.the_geom) 
              AND NOT ST_Touches(p.the_geom, m.the_geom) ) order by p.sicob_id';
        EXCEPTION
        WHEN others THEN
                RAISE EXCEPTION 'geoSICOB (sicob_ungroup_ubication); cobertura:%, error:(%,%)', reloid::text, SQLERRM,SQLSTATE;	
END;
$function$
 