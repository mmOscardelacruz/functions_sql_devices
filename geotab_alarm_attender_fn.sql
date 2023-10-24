-- FUNCTION: public.geotab_alarm_attender_fn(bigint, interval)

-- DROP FUNCTION IF EXISTS public.geotab_alarm_attender_fn(bigint, interval);

CREATE OR REPLACE FUNCTION public.geotab_alarm_attender_fn(
	vidgeotabalarm bigint,
	voffsetint interval)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	RETURN COALESCE((
		SELECT ARRAY_TO_JSON(ARRAY_AGG(users))
		FROM
		(
			SELECT U.Name, U.LastName, U.Username, 
			aga.date_attended + vOffsetInt AS "datetime"
			FROM attendgeotabalarm AS aga
			INNER JOIN "user" AS U
			ON aga.id_user = U.Id
			WHERE aga.id_geotabalarm = vIdGeotabAlarm
			AND aga.date_attended IS NOT NULL
			ORDER BY aga.date_attended ASC
			LIMIT 1
		) AS users
	), '[]'::JSON);
END
$BODY$;

ALTER FUNCTION public.geotab_alarm_attender_fn(bigint, interval)
    OWNER TO mmcam_dev;
