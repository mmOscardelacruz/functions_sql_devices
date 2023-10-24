-- FUNCTION: public.geotab_alarms_for_rule(bigint)

-- DROP FUNCTION IF EXISTS public.geotab_alarms_for_rule(bigint);

CREATE OR REPLACE FUNCTION public.geotab_alarms_for_rule(
	vuserid bigint)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vOffset	INTERVAL;
BEGIN
	vOffset := (SELECT CASE WHEN UC.IsSummertime THEN "offset" + INTERVAL '1H' ELSE TZ."offset" END
				FROM UserConfig AS UC
				INNER JOIN Timezone AS TZ
				ON UC.IdTimezone = TZ.Id
 				WHERE UC.IdUser = vUserId
			    LIMIT 1);
	RETURN 
	COALESCE
	(
		(
			SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
			FROM
			(
				SELECT gr.id_geotabruleserial AS "idRule", gr.name AS "ruleName", COALESCE(gr.description, '') AS "ruleDesc", 
				geotab_alarm_data_for_rule(gr.id_geotabruleserial, vUserId, vOffset) AS "alarms",
				geotab_alarm_cc_for_email(vUserId, gr.id_geotabruleserial) AS "CC",
				gr.secs_preevent AS "secsPreEvent", gr.secs_posevent AS "secsPosEvent"
				FROM geotabrule AS gr
				WHERE gr.id_user = vUserId
				AND gr.is_email
				GROUP BY gr.id_geotabruleserial, gr.name, gr.description, gr.secs_preevent, gr.secs_posevent
				ORDER BY gr.name ASC
			) AS dt
		), '[]'::JSON
	);
END
$BODY$;

ALTER FUNCTION public.geotab_alarms_for_rule(bigint)
    OWNER TO mmcam_dev;
