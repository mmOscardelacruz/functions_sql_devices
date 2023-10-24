-- FUNCTION: public.command_type_select_fn(character varying)

-- DROP FUNCTION IF EXISTS public.command_type_select_fn(character varying);

CREATE OR REPLACE FUNCTION public.command_type_select_fn(
	vsessiontoken character varying)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vIdUser 	BIGINT;
	vLangId		INT;
	vResult		tpResponse;
BEGIN
	--VALIDAR EL TOKEN
	vIdUser := checkValidToken(vSessionToken);
	--OBTENER EL IDIOMA DEL USUARIO
	vLangId := (SELECT language_id FROM userconfig WHERE IdUser = vIdUser);
	--REGRESAR EL RESULTADO CORRECTO
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	vResult.data := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt)) 
							 FROM
							 (
								 SELECT ct.command_type_id AS "commandTypeId",
								 CASE WHEN ctt.name IS NULL THEN ct.name ELSE ctt.name END AS "name"
								 FROM command_type AS ct
								 LEFT JOIN command_type_trans AS ctt
								 ON ct.command_type_id = ctt.command_type_id AND ctt.language_id = vLangId
								 ORDER BY 2 ASC
							 ) AS dt), '[]'::JSON);
	RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.command_type_select_fn(character varying)
    OWNER TO mmcam_dev;
