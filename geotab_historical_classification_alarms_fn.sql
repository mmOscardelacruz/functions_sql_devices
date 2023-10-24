-- FUNCTION: public.geotab_historical_classification_alarms_fn(bigint, interval)

-- DROP FUNCTION IF EXISTS public.geotab_historical_classification_alarms_fn(bigint, interval);

CREATE OR REPLACE FUNCTION public.geotab_historical_classification_alarms_fn(
	vgeotabalarmid bigint,
	voffsetint interval)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	RETURN
	COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
			 FROM
			 (
				 SELECT u.name, u.lastname AS "lastName", u.username,
				 c.comment, cm.classification_message,
				 c.classification_date + vOffsetInt AS "classificationDateTime"
				 FROM classification AS c
				 INNER JOIN "user" AS u
				 on c.id_user = u.Id
				 INNER JOIN classification_messages AS cm
				 ON c.id_classification_message = cm.id_classification_message
				 WHERE c.id_geotabalarm = vGeotabAlarmId
				 ORDER BY c.classification_date DESC
			 ) AS dt), '[]'::JSON);
END
$BODY$;

ALTER FUNCTION public.geotab_historical_classification_alarms_fn(bigint, interval)
    OWNER TO mmcam_dev;
