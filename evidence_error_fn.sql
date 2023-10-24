-- FUNCTION: public.evidence_error_fn(bigint, character varying, integer)

-- DROP FUNCTION IF EXISTS public.evidence_error_fn(bigint, character varying, integer);

CREATE OR REPLACE FUNCTION public.evidence_error_fn(
	vidalarm bigint,
	vsource character varying,
	vlangid integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vGeotab		geotab_download_task;
	vStreamax	streamax_download_task;
BEGIN
	IF (UPPER(vSource) LIKE 'GEOTAB') THEN
		--RAISE NOTICE 'ALARM ID: %', vIdAlarm;
		vGeotab = (SELECT dt FROM geotab_download_task AS dt WHERE id_geotabalarm = vIdAlarm ORDER BY task_date_time DESC LIMIT 1);
		--NO EXISTE EVIDENCIA:
		IF (vGeotab IS NULL) THEN
			RETURN evidence_error_message_select_fn(NULL, NULL, vLangId);
		END IF;
		--BUSCAR SI ESTÁ EN PROCESO DE DESCARGA
		IF (NOT vGeotab.is_deleted AND vGeotab.state = '' AND vGeotab.substate = '') THEN
			RETURN evidence_error_message_select_fn('', '', vLangId);
		END IF;
		--SI TIENE UN TASK ID, REGRESAR EL MOTIVO DE ERROR
		RETURN evidence_error_message_select_fn(vGeotab.state, vGeotab.substate, vLangId);
	ELSE
		vStreamax := (SELECT dt FROM streamax_download_task AS dt WHERE id_received_alarm = vIdAlarm ORDER BY task_date_time DESC LIMIT 1);
		--RAISE NOTICE 'Streamax: %', vStreamax;
		--NO EXISTE EVIDENCIA:
		IF (vStreamax IS NULL) THEN
			RETURN evidence_error_message_select_fn(NULL, NULL, vLangId);
		END IF;
		--BUSCAR SI ESTÁ EN PROCESO DE DESCARGA (NO ELIMINADO PERO SIN MENSAJES DE ERROR)
		IF (NOT vStreamax.is_deleted AND vStreamax.state = '' AND vStreamax.substate = '') THEN
			RETURN evidence_error_message_select_fn('', '', vLangId);
		END IF;
		--SI TIENE UN TASK ID, REGRESAR EL MOTIVO DE ERROR
		RETURN evidence_error_message_select_fn(vStreamax.state, vStreamax.substate, vLangId);
	END IF;
END
$BODY$;

ALTER FUNCTION public.evidence_error_fn(bigint, character varying, integer)
    OWNER TO mmcam_dev;
