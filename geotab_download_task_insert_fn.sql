-- FUNCTION: public.geotab_download_task_insert_fn(json)

-- DROP FUNCTION IF EXISTS public.geotab_download_task_insert_fn(json);

CREATE OR REPLACE FUNCTION public.geotab_download_task_insert_fn(
	vdata json)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	IF (JSON_ARRAY_LENGTH(COALESCE(vData, '[]'::JSON)) <= 0 ) THEN
		RAISE EXCEPTION 'DEBE DE HABER UNO O MÁS ELEMENTOS EN EL ARREGLO';
	END IF;
	INSERT INTO geotab_download_task (id_geotabalarm, task_id, serial_mdvr, cameras, task_date_time, db_date_time, error_code)
	SELECT (dt->>'idGeotabAlarm')::BIGINT, COALESCE(dt->>'taskId', ''), COALESCE(dt->>'serialMdvr', ''),
	COALESCE(dt->'cameras', '[]'::JSON), (dt->>'date')::TIMESTAMPTZ(0), NOW()::TIMESTAMPTZ(0),
	COALESCE(dt->>'errorCode', '')
	FROM JSON_ARRAY_ELEMENTS(vData) AS dt
	ON CONFLICT 
	ON CONSTRAINT geotab_download_task_un
	DO NOTHING;
END
$BODY$;

ALTER FUNCTION public.geotab_download_task_insert_fn(json)
    OWNER TO mmcam_dev;
