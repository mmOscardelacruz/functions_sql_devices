-- FUNCTION: public.code_group_select_fn(character varying)

-- DROP FUNCTION IF EXISTS public.code_group_select_fn(character varying);

CREATE OR REPLACE FUNCTION public.code_group_select_fn(
	vtoken character varying)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vUserId		BIGINT;
	vUserGroups	BIGINT[];
	vResult 	tpResponse;
BEGIN
	--VERIFICAR QUE EL TOKEN SEA VÁLIDO
	vUserId := checkValidToken(vToken);
	vUserGroups := getPlainGroupsAll(vUserId);
	--INICIALIZAR RESPUESTA
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	--OBTENER DATOS
	vResult.data := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
								FROM
								(
									SELECT g.id AS "groupId", g.name, 
									COALESCE(gc.code, '') AS code
									FROM farec.group_code AS gc
									RIGHT JOIN fleet AS g
									ON gc.group_id = g.Id
									WHERE g.Id IN (SELECT * FROM UNNEST(vUserGroups))
									ORDER BY g.id ASC
								) AS dt), '[]'::JSON);
	RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.code_group_select_fn(character varying)
    OWNER TO mmcam_dev;
