SET CLIENT_ENCODING TO 'utf8';
CREATE OR REPLACE FUNCTION public.sicob_cutlineatpoints(param_mlgeom geometry, param_mpgeom geometry, param_tol double precision)
 RETURNS geometry
 LANGUAGE plpgsql
 IMMUTABLE STRICT
AS $function$
DECLARE
	var_resultgeom geometry;
	var_sline geometry;
	var_eline geometry;
	var_perc_line double precision;
	var_refgeom geometry;
	var_pset geometry[] :=
		ARRAY(SELECT geom FROM ST_Dump(param_mpgeom));
	var_lset geometry[] :=
		ARRAY(SELECT geom FROM ST_Dump(param_mlgeom));
BEGIN
	FOR i in 1 .. array_upper(var_pset,1) LOOP
		FOR j in 1 .. array_upper(var_lset,1) LOOP
			IF
				ST_DWithin(var_lset[j],var_pset[i],param_tol) AND
				NOT ST_Intersects(ST_Boundary(var_lset[j]),var_pset[i])
			THEN
				IF ST_NumGeometries(ST_Multi(var_lset[j])) = 1 THEN
					var_perc_line :=
					ST_LineLocatePoint(var_lset[j],var_pset[i]);
					IF var_perc_line BETWEEN 0.0001 and 0.9999 THEN
						var_sline :=
							ST_LineSubString(var_lset[j],0,var_perc_line);
						var_eline :=
							ST_LineSubString(var_lset[j],var_perc_line,1);
						var_eline :=
							ST_SetPoint(var_eline,0,ST_EndPoint(var_sline));
						var_lset[j] := ST_Collect(var_sline,var_eline);
					END IF;
				ELSE
					var_lset[j] :=
					sicob_cutlineatpoints(cast(var_lset[j] as geometry),cast(var_pset[i] as geometry), param_tol);
				END IF;
			END IF;
		END LOOP;
	END LOOP;
	RETURN ST_Union(var_lset);
END;
$function$
 