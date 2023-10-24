-- FUNCTION: public.code_group_delete_fn(character varying, bigint)

-- DROP FUNCTION IF EXISTS public.code_group_delete_fn(character varying, bigint);

CREATE OR REPLACE FUNCTION public.code_group_delete_fn(
	vtoken character varying,
	vgroupid bigint)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vUserId	BIGINT;
	vResult tpResponse;
	/*LANGUAGE*/
	vUserLng	INT;
BEGIN
	--VERIFICAR QUE EL TOKEN SEA VÁLIDO
	vUserId := checkValidToken(vToken);
	--OBTENER EL IDIOMA DEL USUARIO
	vUserLng := (SELECT language_id FROM userconfig WHERE IdUser = vUserId);
	--VERIFICAR QUE EL GRUPO EXISTA
	IF NOT EXISTS (SELECT * FROM farec.group_code WHERE group_id = vGroupId) THEN
		RAISE EXCEPTION '%', message_select_fn(8, 4, vUserLng, 1, '{}'::VARCHAR[]);
	END IF;
	--ELIMINAR INFORMACIÓN 
	DELETE FROM farec.group_code WHERE group_id = vGroupId;
	--INICIALIZAR RESPUESTA
	vResult.code := 200; vResult.status := TRUE; vResult.message := message_select_fn(8, 4, vUserLng, 2, '{}'::VARCHAR[]);
	--OBTENER DATOS
	vResult.data := COALESCE((SELECT ROW_TO_JSON(dt)
					FROM
					(
						SELECT g.id AS "groupId", g.name, 
						COALESCE(gc.code, '') AS code
						FROM farec.group_code AS gc
						RIGHT JOIN fleet AS g
						ON gc.group_id = g.Id
						WHERE g.id = vGroupId
					) AS dt), '{}'::JSON);
	RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.code_group_delete_fn(character varying, bigint)
    OWNER TO mmcam_dev;
