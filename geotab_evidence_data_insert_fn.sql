-- FUNCTION: public.geotab_evidence_data_insert_fn(json)

-- DROP FUNCTION IF EXISTS public.geotab_evidence_data_insert_fn(json);

CREATE OR REPLACE FUNCTION public.geotab_evidence_data_insert_fn(
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
	INSERT INTO geotab_evidence_data (download_id, id_geotabalarm, path, date_time)
	SELECT dt->>'downloadId', (dt->>'idGeotabAlarm')::BIGINT, 
	dt->>'path', NOW()::TIMESTAMPTZ(0)
	FROM JSON_ARRAY_ELEMENTS(vData) AS dt
	ON CONFLICT 
	ON CONSTRAINT geotab_evidence_data_un
	DO NOTHING;
END
$BODY$;

ALTER FUNCTION public.geotab_evidence_data_insert_fn(json)
    OWNER TO mmcam_dev;
