-- FUNCTION: public.download_video_from_geotab_alarm_task_fn()

-- DROP FUNCTION IF EXISTS public.download_video_from_geotab_alarm_task_fn();

CREATE OR REPLACE FUNCTION public.download_video_from_geotab_alarm_task_fn(
	)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE	
	vResult 		tpResponse;
	vDownloadsLeft	JSON;
	vConfig			evidence_configuration;
BEGIN
	vConfig := (SELECT dt FROM evidence_configuration AS dt LIMIT 1);
	vDownloadsLeft := evidence_count_limit_fn((SELECT ARRAY_TO_JSON(ARRAY_AGG(id)) FROM vehicle), vConfig.time_zone)->'data';
	RAISE NOTICE 'DOWNLOADS LEFT: %', vDownloadsLeft;
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	vResult.data := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
					FROM
					(
						SELECT ga.id_geotabalarm AS "idGeotabAlarm", ga.gpstime AS "dateTime",
						gr.secs_preevent AS "secsPreEvent", gr.secs_posevent AS "secsPosEvent",
						gr.gif_required AS "gifRequired", gr.video_required AS "videoRequired",
						v.serialMDVR AS "serialMdvr", ga.gpslat AS latitude, ga.gpslng AS longitude,
						gr.zone_restriction_id_entry AS "zoneRestrictionIdEntry",
						gr.zone_restriction_name_entry AS "zoneRestrictionNameEntry",
						gr.zone_restriction_id_exit AS "zoneRestrictionIdExit",
						gr.zone_restriction_name_exit AS "zoneRestrictionNameExit",
						gr.zone_restriction AS "zoneRestriction",
						(SELECT COALESCE(ARRAY_TO_JSON(ARRAY_AGG(dt)), '[]'::JSON)
						FROM
						(
							SELECT c.name, c.channel
                            FROM camera AS c
                            INNER JOIN camera_type AS ct
                            ON c.camera_type_id = ct.camera_type_id
                            WHERE c.IdVehicle = v.Id
                            AND ct.camera_type_id IN (1,2)
						) AS dt) AS "cameras"
						FROM geotabalarm AS ga
						INNER JOIN geotabrule AS gr
						ON ga.id_geotabruleserial = gr.id_geotabruleserial
						INNER JOIN vehicle AS v
						ON ga.id_vehicle = v.Id
						INNER JOIN JSON_ARRAY_ELEMENTS(vDownloadsLeft) AS downloadsLeft
						ON v.id = (downloadsLeft->>'vehicleId')::BIGINT
						WHERE NOT EXISTS (SELECT * FROM geotab_download_task WHERE id_geotabalarm = ga.id_geotabalarm)
						AND NOT EXISTS (SELECT * FROM task_video_data WHERE id_geotabalarm IS NOT NULL AND id_geotabalarm = ga.id_geotabalarm)
						AND ga.gpstime BETWEEN (select NOW() - INTERVAL '12H') AND NOW() + INTERVAL '1 Day'
						AND (downloadsLeft->>'evidencesLeft')::INT > 0
						ORDER BY ga.gpsTime DESC
					) AS dt), '[]'::JSON);
	RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.download_video_from_geotab_alarm_task_fn()
    OWNER TO mmcam_dev;
