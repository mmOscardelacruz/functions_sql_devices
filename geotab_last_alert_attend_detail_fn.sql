-- FUNCTION: public.geotab_last_alert_attend_detail_fn(bigint, interval, integer)

-- DROP FUNCTION IF EXISTS public.geotab_last_alert_attend_detail_fn(bigint, interval, integer);

CREATE OR REPLACE FUNCTION public.geotab_last_alert_attend_detail_fn(
	vidgeotabalarm bigint,
	voffsetint interval,
	vuserlng integer)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	RETURN 
	(
		COALESCE((SELECT ROW_TO_JSON(dt)
		FROM
		(
			SELECT CASE WHEN cmt.classification_message IS NULL THEN COALESCE(cm.classification_message, '')
			ELSE cmt.classification_message END AS "classification",
			(SELECT calification FROM historical_geotab_alarm_classification WHERE id_geotabalarm = vIdGeotabAlarm ORDER BY date_time DESC LIMIT 1) AS "isVerified",
			c.comment, c.classification_date + vOffsetInt AS "classificationDate"
			FROM classification AS c
			LEFT JOIN classification_messages AS cm
			ON c.id_classification_message = cm.id_classification_message
			LEFT JOIN classification_message_trans AS cmt
			ON cm.id_classification_message = cmt.id_classification_message AND cmt.language_id = vUserLng
			WHERE c.id_geotabalarm = vIdGeotabAlarm
			ORDER BY c.classification_date DESC LIMIT 1
		) AS dt), '{}')
	);
END
$BODY$;

ALTER FUNCTION public.geotab_last_alert_attend_detail_fn(bigint, interval, integer)
    OWNER TO mmcam_dev;
