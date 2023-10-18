-- FUNCTION: public.driver_for_identification_task(timestamp without time zone, timestamp without time zone)

-- DROP FUNCTION IF EXISTS public.driver_for_identification_task(timestamp without time zone, timestamp without time zone);

CREATE OR REPLACE FUNCTION public.driver_for_identification_task(
	vfromdate timestamp without time zone DEFAULT NULL::timestamp without time zone,
	vtodate timestamp without time zone DEFAULT NULL::timestamp without time zone)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$

BEGIN
	IF (vFromDate IS NOT NULL AND vToDate IS NOT NULL) THEN
		RETURN
		COALESCE(
			(
				SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
				FROM
				(
					SELECT ra."idAlarm", vmg.geotab_go_id AS "goId",
					ra."utcTime"
					FROM
					(
						SELECT DISTINCT ra.id AS "idAlarm", ra.utc_time AS "utcTime", ra.idvehicle AS "idVehicle"
						FROM receivedalarm AS ra
						WHERE ra.utc_time BETWEEN vFromDate AND vToDate
					) AS ra
					-- Cambio: INNER JOIN con vehicle_device
					INNER JOIN vehicle_device AS vd ON ra."idVehicle" = vd.vehicle_id
					--INNER JOIN vehicle AS v
					ON ra."idVehicle" = v.id
					INNER JOIN vehicle_mdvr_go AS vmg
					ON vmg.vehicle_id = v.id
					LEFT JOIN driver_alarm_identification_log AS dail
					ON dail.received_alarm_id = ra."idAlarm"
					WHERE dail.received_alarm_id IS NULL
				) AS dt
			), '[]'::JSON
		);
	ELSE
		RETURN
		COALESCE(
			(
				SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
				FROM
				(
					SELECT ra."idAlarm", vmg.geotab_go_id AS "goId",
					ra."utcTime"
					FROM
					(
						SELECT DISTINCT ra.id AS "idAlarm", ra.utc_time AS "utcTime", ra.idvehicle AS "idVehicle"
						FROM receivedalarm AS ra
						WHERE ra.utc_time >= (SELECT NOW() - INTERVAL '12H')
					) AS ra
					-- INNER JOIN vehicle AS v
					-- ON ra."idVehicle" = v.id
					-- INNER JOIN vehicle_mdvr_go AS vmg
					-- ON vmg.vehicle_id = v.id
					-- LEFT JOIN driver_alarm_identification_log AS dail
					-- ON dail.received_alarm_id = ra."idAlarm"
					-- WHERE dail.received_alarm_id IS NULL
					-- Cambio: INNER JOIN con vehicle_device
					INNER JOIN vehicle_device AS vd 
					ON ra."idVehicle" = vd.vehicle_id
					INNER JOIN vehicle_mdvr_go AS vmg 
					ON vmg.vehicle_id = vd.vehicle_id
					LEFT JOIN driver_alarm_identification_log AS dail 
					ON dail.received_alarm_id = ra."idAlarm"
					WHERE dail.received_alarm_id IS NULL
				) AS dt
			), '[]'::JSON
		);
	END IF;
END
$BODY$;

ALTER FUNCTION public.driver_for_identification_task(timestamp without time zone, timestamp without time zone)
    OWNER TO mmcam_dev;
