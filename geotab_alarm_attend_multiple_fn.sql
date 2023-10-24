-- FUNCTION: public.geotab_alarm_attend_multiple_fn(character varying, json)

-- DROP FUNCTION IF EXISTS public.geotab_alarm_attend_multiple_fn(character varying, json);

CREATE OR REPLACE FUNCTION public.geotab_alarm_attend_multiple_fn(
	vtoken character varying,
	vdata json DEFAULT '[]'::json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vResult 		tpResponse;
	vIdUser			BIGINT;
	vUserLng		INT;
	vAttendedDate	TIMESTAMPTZ(0);
	vAttended		JSON;
	vUnattended		JSON;
BEGIN
	vIdUser := checkValidToken(vToken);
	--OBTENER EL IDIOMA DEL USUARIO
	vUserLng := (SELECT language_id FROM userconfig WHERE IdUser = vIdUser);
	--VERIFICAR QUE EL ARREGLO NO ESTÉ VACÍO
	IF(JSON_ARRAY_LENGTH(COALESCE(vData, '[]'::JSON)) <= 0) THEN
		RAISE EXCEPTION 'Debe de seleccionar por lo menos un elemento a atender'; --IDIOMA
	END IF;
	--ASIGNAR LA FECHA DE ATENCIÓN (PARA QUE NO DIFIERA EN EL TIEMPO LOS MÚLTIPLES PROCESOS QUE SE HARÁN)
	vAttendedDate := NOW();
	--INSERTAR LAS ALERTAS QUE NO EXISTAN PARA ESE USUARIO *VER NOTA AL FINAL
	INSERT INTO AttendGeotabAlarm(id_geotabalarm, id_user, date_attended)
	SELECT dt::TEXT::BIGINT, vIdUser, vAttendedDate
	FROM JSON_ARRAY_ELEMENTS(vData) AS dt
	WHERE NOT EXISTS (SELECT * FROM attendGeotabAlarm WHERE id_geotabalarm = dt::TEXT::INT AND id_user = vIdUser);
	--MODIFICAR LAS ALERTAS QUE YA EXISTÍAN Y SE ESTÁN ATENDIENDO
	UPDATE AttendGeotabAlarm SET date_attended = vAttendedDate
	WHERE id_geotabalarm IN (SELECT dt::TEXT::BIGINT FROM JSON_ARRAY_ELEMENTS(vData) AS dt)
	AND id_user = vIdUser;
	--MODIFICAR LAS ALERTAS PARA QUE SE ATIENDAN PARA LOS DEMÁS USUARIOS
	UPDATE AttendGeotabAlarm SET date_attended = vAttendedDate + INTERVAL '1S'
	WHERE id_geotabalarm IN (SELECT dt::TEXT::BIGINT FROM JSON_ARRAY_ELEMENTS(vData) AS dt) AND id_user <> vIdUser;
	--VERIFICAR LOS QUE SE ATENDIERON Y LAS QUE NO
	vAttended := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
						  FROM
						  (
							  SELECT ga.id_geotabalarm, gr.name
							  FROM attendGeotabAlarm aga
							  INNER JOIN geotabalarm AS ga
							  ON aga.id_geotabalarm = ga.id_geotabalarm
							  INNER JOIN geotabrule AS gr
							  ON ga.id_geotabruleserial = gr.id_geotabruleserial
							  WHERE ga.id_geotabalarm IN (SELECT dt::TEXT::BIGINT FROM JSON_ARRAY_ELEMENTS(vData) AS dt)
							  AND aga.date_attended IS NOT NULL
							  GROUP BY ga.id_geotabalarm, gr.name
						  ) AS dt), '[]'::JSON);
	vUnattended := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
						  FROM
						  (
							  SELECT ga.id_geotabalarm, gr.name
							  FROM attendGeotabAlarm aga
							  INNER JOIN geotabalarm AS ga
							  ON aga.id_geotabalarm = ga.id_geotabalarm
							  INNER JOIN geotabrule AS gr
							  ON ga.id_geotabruleserial = gr.id_geotabruleserial
							  WHERE ga.id_geotabalarm IN (SELECT dt::TEXT::BIGINT FROM JSON_ARRAY_ELEMENTS(vData) AS dt)
							  AND aga.date_attended IS NULL
							  GROUP BY ga.id_geotabalarm, gr.name
						  ) AS dt), '[]'::JSON);
	--REGRESAR RESULTADOS
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	vResult.data := JSON_BUILD_OBJECT('attendedAlarms', vAttended, 'unattendedAlarms', vUnattended);
	RETURN TO_JSON(vResult);
	/*
		NOTA:
		[2021-11-11] Héctor Saldívar:
		Por petición de sprints pasados (inicios de la codificación del proyecto) se pidió
		que los usuarios en los mismos grupos deben de ser capaces de ver la misma información
		(incluso si estos se dieron de alta hasta después de que pasaran las alertas)
		por lo cual el trigger que se encarga de copiar una alarma a todos los usuarios 
		pertinentes omitirá a los usuarios que se hayan agregado al sistema después de que 
		una alarma se haya generado y copiado a los usuarios existentes en ese momento.
		Para corregir ese problema se hace un LEFT JOIN a la tabla de copias
		por si un usuario no existe aquí, pueda recibir la alarma.
		En tal caso, debemos de insertar la copia en este momento para notificarle al sistema
		que el usuario X se registró después pero ya tiene acceso a esa parte.
	*/
END
$BODY$;

ALTER FUNCTION public.geotab_alarm_attend_multiple_fn(character varying, json)
    OWNER TO mmcam_dev;
