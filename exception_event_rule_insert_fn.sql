-- FUNCTION: public.exception_event_rule_insert_fn(json)

-- DROP FUNCTION IF EXISTS public.exception_event_rule_insert_fn(json);

CREATE OR REPLACE FUNCTION public.exception_event_rule_insert_fn(
	vdata json)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	--VERIFICAR QUE LOS DATOS NO ESTÉN VACÍOS
	IF(JSON_ARRAY_LENGTH(COALESCE(vData, '[]'::JSON)) <= 0) THEN
		RAISE EXCEPTION 'LOS DATOS A ENVIAR NO PUEDEN ESTAR VACÍOS';
	END IF;
	--GUARDAR INFORMACIÓN DE EXCEPCIONES
	INSERT INTO exception_event (active_from, active_to, rule_id, device_id, driver)
	SELECT dt.active_from, dt.active_to, dt.rule_id, dt.device_id, dt.driver
	FROM JSON_POPULATE_RECORDSET(NULL::exception_event, vData) AS dt
	ON CONFLICT ON CONSTRAINT exception_event_un 
	DO NOTHING;
	RETURN TRUE;
END
$BODY$;

ALTER FUNCTION public.exception_event_rule_insert_fn(json)
    OWNER TO mmcam_dev;
