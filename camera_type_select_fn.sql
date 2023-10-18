-- FUNCTION: public.camera_type_select_fn(character varying)

-- DROP FUNCTION IF EXISTS public.camera_type_select_fn(character varying);

CREATE OR REPLACE FUNCTION public.camera_type_select_fn(
	vtoken character varying)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
 
DECLARE
	vResult tpResponse;
	vIdUser	BIGINT;
	vLangId	INT;
BEGIN
	vIdUser := checkValidToken(vToken);
	--OBTENER EL IDIOMA DEL USUARIO
	vLangId := (SELECT language_id FROM userconfig WHERE IdUser = vIdUser);
	--INICIALIZAR LAS VARIABLES Y REGRESAR RESULTADOS
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	vResult.data := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
							 FROM
							 (
								 SELECT ct.camera_type_id AS "cameraTypeId", 
								 CASE WHEN ctt.name IS NULL THEN ct.name ELSE ctt.name END AS "cameraType" 
								 FROM camera_type AS ct
								 LEFT JOIN camera_type_trans ctt
								 ON ct.camera_type_id = ctt.camera_type_id AND ctt.language_id = vLangId
							 ) AS dt), '[]'::JSON);
	RETURN TO_JSON(vResult);
END
$BODY$;

