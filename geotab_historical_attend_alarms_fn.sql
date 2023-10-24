-- FUNCTION: public.geotab_historical_attend_alarms_fn(bigint, interval)

-- DROP FUNCTION IF EXISTS public.geotab_historical_attend_alarms_fn(bigint, interval);

CREATE OR REPLACE FUNCTION public.geotab_historical_attend_alarms_fn(
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
				 aga.date_attended + vOffsetInt AS "attendedDateTime"
				 FROM attendGeotabAlarm AS aga
				 INNER JOIN "user" AS u
				 on aga.id_user = u.Id
				 WHERE aga.id_geotabalarm = vGeotabAlarmId
				 ORDER BY aga.date_attended DESC
			 ) AS dt), '[]'::JSON);
END
$BODY$;

ALTER FUNCTION public.geotab_historical_attend_alarms_fn(bigint, interval)
    OWNER TO mmcam_dev;
