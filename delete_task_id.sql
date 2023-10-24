-- FUNCTION: public.delete_task_id(bigint, character varying, character varying, character varying, character varying)

-- DROP FUNCTION IF EXISTS public.delete_task_id(bigint, character varying, character varying, character varying, character varying);

CREATE OR REPLACE FUNCTION public.delete_task_id(
	vidalarm bigint,
	vtaskid character varying,
	vsource character varying,
	vstate character varying DEFAULT ''::character varying,
	vsubstate character varying DEFAULT ''::character varying)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	IF (COALESCE(vIdAlarm, 0) <= 0) THEN
		RAISE EXCEPTION 'Debe de ingresar un id de alarma';
	END IF;
	IF(LENGTH(COALESCE(vSource, '')) <= 0) THEN
		RAISE EXCEPTION 'Debe de ingresar alguna fuente de datos';
	END IF;
	/*IF(LENGTH(COALESCE(vTaskId, '')) <= 0) THEN
		RAISE EXCEPTION 'Debe de ingresar un TASK ID';
	END IF;*/
	IF (UPPER(vSource) LIKE 'GEOTAB') THEN
		--DELETE FROM geotab_download_task WHERE id_geotabalarm = vIdAlarm AND task_id = vTaskId;
		IF(LENGTH(COALESCE(vTaskId, '')) <= 0) THEN
			INSERT INTO geotab_download_task (id_geotabalarm, state, substate, is_deleted, task_date_time, db_date_time)
			VALUES (vState, vSubState, TRUE, NOW(), NOW());
		ELSE
			UPDATE geotab_download_task SET (state, substate, is_deleted) = (vState, vSubState, TRUE)
			WHERE id_geotabalarm = vIdAlarm AND task_id = vTaskId;
		END IF;
	ELSE IF (UPPER(vSource) LIKE 'STREAMAX') THEN
		--DELETE FROM streamax_download_task WHERE id_received_alarm = vIdAlarm AND task_id = vTaskId;
		IF(LENGTH(COALESCE(vTaskId, '')) <= 0) THEN
			INSERT INTO streamax_download_task (id_received_alarm, state, substate, is_deleted, task_date_time, db_date_time) 
			VALUES (vIdAlarm, vState, vSubState, TRUE, NOW(), NOW());
		ELSE
			UPDATE streamax_download_task SET (state, substate, is_deleted) = (vState, vSubState, TRUE)
			WHERE id_received_alarm = vIdAlarm AND task_id = vTaskId;
		END IF;
	ELSE
		RAISE EXCEPTION 'La Fuente no es válida';
	END IF;
	END IF;
RETURN TRUE;
END
$BODY$;

ALTER FUNCTION public.delete_task_id(bigint, character varying, character varying, character varying, character varying)
    OWNER TO mmcam_dev;
