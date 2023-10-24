-- FUNCTION: public.code_group_update_fn(character varying, bigint, character varying)

-- DROP FUNCTION IF EXISTS public.code_group_update_fn(character varying, bigint, character varying);

CREATE OR REPLACE FUNCTION public.code_group_update_fn(
	vtoken character varying,
	vgroupid bigint,
	vcode character varying)
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
	--VERIFICAR QUE EL CÓDIGO INGRESADO NO ESTÉ NULO O VACÍO
	IF(vCode IS NULL) THEN 
		RAISE EXCEPTION '%', message_select_fn(8, 2, vUserLng, 1, '{}'::VARCHAR[]);
	END IF;
	IF (LENGTH(vCode) < 3) THEN
		RAISE EXCEPTION '%', message_select_fn(8, 2, vUserLng, 2, '{}'::VARCHAR[]);
	END IF;
	--VERIFICAR QUE EL CÓDIGO NO EXISTA
	IF EXISTS(SELECT * FROM farec.group_code WHERE UPPER(code) LIKE UPPER(vCode) AND group_id <> vGroupId) THEN
		RAISE EXCEPTION '%',message_select_fn(8, 2, vUserLng, 3, '{}'::VARCHAR[]);
	END IF;
	--VERIFICAR QUE EL GRUPO EXISTA
	IF NOT EXISTS (SELECT * FROM fleet WHERE id = vGroupId) THEN
		RAISE EXCEPTION '%', message_select_fn(8, 2, vUserLng, 4, '{}'::VARCHAR[]);
	END IF;
	--ACTUALIZAR INFORMACIÓN
	IF NOT EXISTS (SELECT * FROM farec.group_code WHERE group_id = vGroupId) THEN
		INSERT INTO farec.group_code (group_id, code) VALUES (vGroupId, vCode);
	ELSE
		UPDATE farec.group_code SET code = vCode WHERE group_id = vGroupId;
	END IF;
	--INICIALIZAR RESPUESTA
	vResult.code := 200; vResult.status := TRUE; vResult.message := message_select_fn(8, 2, vUserLng, 5, ARRAY[vCode]::VARCHAR[]);
	--OBTENER DATOS
	vResult.data := COALESCE((SELECT ROW_TO_JSON(dt)
					FROM
					(
						SELECT g.id AS "groupId", g.name, 
						COALESCE(gc.code, '') AS code
						FROM farec.group_code AS gc
						INNER JOIN fleet AS g
						ON gc.group_id = g.Id
						WHERE g.id = vGroupId
					) AS dt), '{}'::JSON);
	RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.code_group_update_fn(character varying, bigint, character varying)
    OWNER TO mmcam_dev;
