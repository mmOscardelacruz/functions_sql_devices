-- FUNCTION: public.driver_alarm_identification_insert_task(json)

-- DROP FUNCTION IF EXISTS public.driver_alarm_identification_insert_task(json);

CREATE OR REPLACE FUNCTION public.driver_alarm_identification_insert_task(
	vdata json)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	--VERIFICAR QUE LOS DATOS NO VENGAN VACÍOS
	IF(JSON_ARRAY_LENGTH(COALESCE(vData, '[]')) <= 0) THEN
		RAISE EXCEPTION 'LOS DATOS NO PUEDEN ESTAR VACÍOS';
	END IF;
	--ACTUALIZAR LOS DATOS DE LA TABLA DE EXCEPCIONES
	UPDATE receivedalarm SET driver_id = dt."driverId", driver_name = dt."driverName"
	FROM
	(
		SELECT (dt->>'idAlarm')::BIGINT AS "idAlarm", dt->>'driverId' AS "driverId", dt->>'driverName' AS "driverName"
		FROM JSON_ARRAY_ELEMENTS(vData) AS dt
	) AS dt
	WHERE receivedalarm.id = dt."idAlarm";
	--INSERTAR LAS ALARMAS QUE SE ACTUALIZARON
	INSERT INTO driver_alarm_identification_log (received_alarm_id, date_time)
	SELECT (dt->>'idAlarm')::BIGINT, NOW()
	FROM JSON_ARRAY_ELEMENTS(vData) AS dt
	ON CONFLICT ON CONSTRAINT driver_identification_un
	DO UPDATE SET date_time = NOW();
	--PERFORM pg_notify('test_drivers', 'ENVÍO CORRECTO');
	RETURN TRUE;
END
$BODY$;

ALTER FUNCTION public.driver_alarm_identification_insert_task(json)
    OWNER TO mmcam_dev;
