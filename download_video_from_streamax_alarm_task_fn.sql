-- FUNCTION: public.download_video_from_streamax_alarm_task_fn()

-- DROP FUNCTION IF EXISTS public.download_video_from_streamax_alarm_task_fn();

CREATE OR REPLACE FUNCTION public.download_video_from_streamax_alarm_task_fn(
	)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE 
    vResult tpResponse;
	vDownloadsLeft	JSON;
	vConfig			evidence_configuration;
BEGIN
	vConfig := (SELECT dt FROM evidence_configuration AS dt LIMIT 1);
	vDownloadsLeft := evidence_count_limit_fn((SELECT ARRAY_TO_JSON(ARRAY_AGG(id)) FROM vehicle), vConfig.time_zone)->'data';
	--RAISE NOTICE 'DOWNLOADS LEFT: %', vDownloadsLeft;
    vResult.code := 200; vResult.status := TRUE; vResult.message := '';
    vResult.data := (SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
                    FROM
                    (
                        SELECT ra.Id AS "idAlarm", ra.gpstime AS "dateTime",
                        r.secspreevent AS "secsPreEvent", r.secsposevent AS "secsPosEvent",
                        r.gif_required AS "gifRequired", r.video_required AS "videoRequired",
                        v.serialMDVR AS "serialMdvr",
                        COALESCE(vmg.geotab_go_id, '') as "goId", ra.utc_time AS "utcTime",
                        (SELECT COALESCE(ARRAY_TO_JSON(ARRAY_AGG(dt)), '[]'::JSON)
                        FROM
                        (
                            SELECT c.name, c.channel
                            FROM camera AS c
                            INNER JOIN camera_type AS ct
                            ON c.camera_type_id = ct.camera_type_id
                            WHERE c.IdVehicle = v.Id
                            AND ct.camera_type_id IN (1,2)
                        ) AS dt) AS "cameras",
                        ra.alarm_id AS "streamaxId", ra.gpslng AS longitude,
						ra.gpslat AS latitude, 
						r.zone_restriction_id_entry AS "zoneRestrictionIdEntry",
						r.zone_restriction_name_entry AS "zoneRestrictionNameEntry",
						r.zone_restriction_id_exit AS "zoneRestrictionIdExit",
						r.zone_restriction_name_exit AS "zoneRestrictionNameExit",
						r.zone_restriction AS "zoneRestriction"
                        FROM ONLY receivedalarm AS ra
                        INNER JOIN vehicle AS v
                        ON ra.idvehicle = v.id
                        LEFT JOIN vehicle_mdvr_go as vmg
                        ON v.id = vmg.vehicle_id
                        INNER JOIN sendrule AS sr
                        ON sr.idreceivedalarm = ra.id
                        INNER JOIN "rule" AS r
                        ON sr.idrule = r.id
						INNER JOIN JSON_ARRAY_ELEMENTS(vDownloadsLeft) AS downloadsLeft
						ON v.id = (downloadsLeft->>'vehicleId')::BIGINT
						LEFT JOIN streamax_download_task AS sdt
						ON ra.id = sdt.id_received_alarm
						LEFT JOIN task_video_data AS tvd
						ON ra.id = tvd.id_alarm
                        --WHERE ra.id NOT IN (SELECT id_received_alarm FROM streamax_download_task)
						WHERE sdt.id_received_alarm IS NULL
                        --AND ra.id NOT IN (SELECT DISTINCT id_alarm FROM task_video_data WHERE id_alarm IS NOT NULL)
						AND tvd.id_alarm IS NULL
                        AND ra.gpstime BETWEEN (select NOW() - INTERVAL '12H') AND NOW() + INTERVAL '1 Day'
                        AND ra.alarm_id IS NOT NULL --PORQUE NO SE VAN A DESCARGAR VIDEOS TEMPORALMENTE DE RECONOCIMIENTO FACIAL HASTA QUE SE TENGA RESPUESTA DE STREAMAX [Israel - 2022 02 22]
                        --AND ra.type <> 56005 --PORQUE NO SE VAN A DESCARGAR VIDEOS TEMPORALMENTE DE RECONOCIMIENTO FACIAL HASTA QUE SE TENGA RESPUESTA DE STREAMAX [Israel - 2022 02 22]
						AND ra.type IN (56006,56000,56002,56004)
						AND (downloadsLeft->>'evidencesLeft')::INT > 0
                        GROUP BY ra.id, ra.gpstime, r.secspreevent, r.secsposevent,
                        r.gif_required, r.video_required, v.serialMDVR, v.Id, vmg.geotab_go_id, ra.utc_time, r.zone_restriction_id_entry, r.zone_restriction_name_entry,
						r.zone_restriction_id_exit, r.zone_restriction_name_exit, r.zone_restriction
                        ORDER BY ra.gpsTime DESC
                    ) AS dt);
    RETURN TO_JSON(vResult);
	/*
		ALARMAS QUE SUBIRÁN EVIDENCIA A PETICIÓN DE ISRAEL PARA BAJAR USO DE RECURSOS 
		EN FTAPI Y SERVIDOR DE EVIDENCIAS
		2022-05-31
		Colision Frontal	56006
		Fatiga				56000
		Llamada Telefonica	56002
		Distraccion			56004
	*/
END
$BODY$;

ALTER FUNCTION public.download_video_from_streamax_alarm_task_fn()
    OWNER TO mmcam_dev;
