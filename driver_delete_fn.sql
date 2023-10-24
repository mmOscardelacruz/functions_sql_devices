-- FUNCTION: public.driver_delete_fn(character varying, integer)

-- DROP FUNCTION IF EXISTS public.driver_delete_fn(character varying, integer);

CREATE OR REPLACE FUNCTION public.driver_delete_fn(
	vtoken character varying,
	vdriverid integer)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
	DECLARE
		vUserId		BIGINT;
		vResult 	tpResponse;
		/*LANGUAGE*/
		vUserLng	INT;
		vUsername varchar;
		--vMessage	VARCHAR;
	BEGIN
		--VERIFICAR QUE EL TOKEN SEA VÁLIDO
		vUserId := checkValidToken(vToken);
			vUsername := (SELECT username FROM "user" WHERE id = vUserId);
		--OBTENER EL IDIOMA DEL USUARIO
		vUserLng := (SELECT language_id FROM userconfig WHERE IdUser = vUserId);
		--VERIFICAR QUE EL CONDUCTOR EXISTA
		IF NOT EXISTS (SELECT * FROM farec.driver WHERE driver_id = vDriverId) THEN
			--vMessage := message_select_fn(11, 4, vUserLng, 1, '{}'::VARCHAR[]);
			RAISE EXCEPTION '%', message_select_fn(11, 4, vUserLng, 1, '{}'::VARCHAR[]);
		END IF;
		--SOFT DELETE
		PERFORM auditlog_insert_fn(vUsername, 'Conductores.', 'Conductor eliminado',
			CONCAT('Se eliminó al conductor ', (select name from farec.driver where driver_id = vDriverId) ,' ',(select last_name from farec.driver where driver_id = vDriverId)));

		DELETE FROM farec.face WHERE driver_id = vDriverId;
		DELETE FROM farec.profile_picture WHERE driver_id = vDriverId;
		DELETE FROM farec.driver_vehicle WHERE driver_id = vDriverId;
		DELETE FROM farec.driver_group WHERE driver_id = vDriverId;
		DELETE FROM farec.driver_rule WHERE driver_id = vDriverId;
		DELETE FROM farec.driver WHERE driver_id = vDriverId;
		vResult.code := 200; vResult.status := TRUE; vResult.message := message_select_fn(11, 4, vUserLng, 2, '{}'::VARCHAR[]);
		--OBTENER DATOS
		vResult.data := TO_JSON(true);
		RETURN TO_JSON(vResult);
	END
$BODY$;

ALTER FUNCTION public.driver_delete_fn(character varying, integer)
    OWNER TO mmcam_dev;
