-- FUNCTION: public.geotab_alarm_cc_for_email(bigint, bigint)

-- DROP FUNCTION IF EXISTS public.geotab_alarm_cc_for_email(bigint, bigint);

CREATE OR REPLACE FUNCTION public.geotab_alarm_cc_for_email(
	vuserid bigint,
	vgeotabruleid bigint)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	RETURN
	COALESCE
	((SELECT ARRAY_TO_JSON(ARRAY_AGG(Email))
	 FROM EmailByGeotabRule AS ebg
	 INNER JOIN Email AS E
	 ON ebg.id_mail = E.id
	 INNER JOIN "user" AS u
	 ON UPPER(u.username) LIKE UPPER(e.email)
	 WHERE ebg.id_geotabruleserial = vGeotabRuleId
	 AND Email <> (SELECT username FROM "user" WHERE Id = vUserId)
	 ),'[]'::JSON
	);
END
$BODY$;

ALTER FUNCTION public.geotab_alarm_cc_for_email(bigint, bigint)
    OWNER TO mmcam_dev;
