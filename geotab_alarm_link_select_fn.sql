-- FUNCTION: public.geotab_alarm_link_select_fn(bigint, json, character varying)

-- DROP FUNCTION IF EXISTS public.geotab_alarm_link_select_fn(bigint, json, character varying);

CREATE OR REPLACE FUNCTION public.geotab_alarm_link_select_fn(
	vidgeotabalarm bigint,
	vchannels json DEFAULT '[]'::json,
	vsource character varying DEFAULT 'geotab'::character varying)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vChnlArr	INT[];
BEGIN
	IF (JSON_ARRAY_LENGTH(COALESCE(vChannels, '[]'::JSON)) <= 0) THEN
		IF (vSource LIKE 'geotab') THEN
			vChnlArr := (SELECT ARRAY_AGG(DISTINCT channel) FROM task_video_data WHERE id_geotabalarm = vIdGeotabAlarm);
		ELSE
			vChnlArr := (SELECT ARRAY_AGG(DISTINCT channel) FROM task_video_data WHERE id_alarm = vIdGeotabAlarm);
		END IF;
	ELSE
		vChnlArr := (SELECT ARRAY_AGG(dt::TEXT::INT) FROM JSON_ARRAY_ELEMENTS(vChannels) AS dt);
	END IF;
	RAISE NOTICE 'Channels: %', vChnlArr;
	
	IF (vSource LIKE 'geotab') THEN
		RAISE NOTICE 'Geotab';
		RETURN
		(
			COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
					 FROM
					 (
						 /*
						 SELECT serial_mdvr AS "serialMdvr", chnl AS "channel", location
						 FROM geotab_alarm_link 
						 WHERE id_geotabalarm = vIdGeotabAlarm
						 AND chnl IN (SELECT * FROM UNNEST(vChnlArr))*/
						 SELECT serial_mdvr AS "serialMdvr", channel, MAX(download_id) AS "downloadId"
						 FROM task_video_data
						 WHERE id_geotabalarm IS NOT NULL
						 AND id_geotabalarm = vIdGeotabAlarm
						 AND channel IN (SELECT * FROM UNNEST(vChnlArr) AS dt)
						 GROUP BY serial_mdvr, channel
					 ) AS dt), '[]'::JSON)
		);
	ELSE
		RAISE NOTICE 'Streamax';
		RETURN
		(
			COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
					 FROM
					 (
						 /*
						 SELECT serial_mdvr AS "serialMdvr", chnl AS "channel", location
						 FROM geotab_alarm_link 
						 WHERE id_geotabalarm = vIdGeotabAlarm
						 AND chnl IN (SELECT * FROM UNNEST(vChnlArr))*/
						 SELECT serial_mdvr AS "serialMdvr", channel, MAX(download_id) AS "downloadId"
						 FROM task_video_data
						 WHERE id_alarm IS NOT NULL
						 AND id_alarm = vIdGeotabAlarm
						 AND channel IN (SELECT * FROM UNNEST(vChnlArr) AS dt)
						 GROUP BY serial_mdvr, channel
					 ) AS dt), '[]'::JSON)
		);
	END IF;
END
$BODY$;

ALTER FUNCTION public.geotab_alarm_link_select_fn(bigint, json, character varying)
    OWNER TO mmcam_dev;
