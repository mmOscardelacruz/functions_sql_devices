-- FUNCTION: public.geotab_alarm_link_insert_fn(json)

-- DROP FUNCTION IF EXISTS public.geotab_alarm_link_insert_fn(json);

CREATE OR REPLACE FUNCTION public.geotab_alarm_link_insert_fn(
	vdata json)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	IF (JSON_ARRAY_LENGTH(COALESCE(vData, '[]'::JSON)) <= 0) THEN
		RAISE EXCEPTION 'EL ARREGLO DEBE DE TENER POR LO MENOS UN OBJETO';
	END IF;
	INSERT INTO geotab_alarm_link (id_geotabalarm, id_vehicle, serial_mdvr, chnl, "location", date_time)
	SELECT (dt->>'idGeotabAlarm')::BIGINT, (dt->>'idVehicle')::BIGINT, dt->>'serialMdvr', (dt->>'chnl')::INT,
	dt->'location', NOW()
	FROM JSON_ARRAY_ELEMENTS(vData) AS dt
	ON CONFLICT ON CONSTRAINT geotab_alarm_link_un
	DO NOTHING;
END
$BODY$;

ALTER FUNCTION public.geotab_alarm_link_insert_fn(json)
    OWNER TO mmcam_dev;
