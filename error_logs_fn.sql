-- FUNCTION: public.error_logs_fn(character varying, json, character varying)

-- DROP FUNCTION IF EXISTS public.error_logs_fn(character varying, json, character varying);

CREATE OR REPLACE FUNCTION public.error_logs_fn(
	videntifier character varying,
	verror json,
	vmodule character varying)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	IF (vError IS NULL) THEN
		RAISE NOTICE 'El Error no puede ser nulo o vacío';
	END IF;
	IF (LENGTH(COALESCE(vIdentifier, '')) <= 0) THEN
		RAISE NOTICE 'El Identificador no puede estar nulo o vacío';
	END IF;
	IF (LENGTH(COALESCE(vModule, '')) <= 0) THEN
		RAISE NOTICE 'El Módulo no puede estar nulo o vacío';
	END IF;
	
	INSERT INTO error_log (date_time, identifier, error, module)
	VALUES (NOW(), vIdentifier, vError, vModule);
END
$BODY$;

ALTER FUNCTION public.error_logs_fn(character varying, json, character varying)
    OWNER TO mmcam_dev;
