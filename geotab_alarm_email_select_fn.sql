-- FUNCTION: public.geotab_alarm_email_select_fn()

-- DROP FUNCTION IF EXISTS public.geotab_alarm_email_select_fn();

CREATE OR REPLACE FUNCTION public.geotab_alarm_email_select_fn(
	)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	RETURN 
	COALESCE
	(
		(SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
		FROM
		(
			SELECT dt.*, COALESCE(geotab_alarms_for_rule(dt."userId"), '[]'::JSON) AS "rules"
			FROM
			(
				SELECT u.Id AS "userId", u.username,
				getUserConfig(u.Id) AS "config"
				FROM geotabrule AS gr
				INNER JOIN "user" AS u
				ON gr.id_user = u.id
				GROUP BY u.id, u.username
			) AS dt
		) AS dt), '[]'::JSON
	);
END
$BODY$;

ALTER FUNCTION public.geotab_alarm_email_select_fn()
    OWNER TO mmcam_dev;
