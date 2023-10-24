-- FUNCTION: public.geotab_rule_email_fn(bigint)

-- DROP FUNCTION IF EXISTS public.geotab_rule_email_fn(bigint);

CREATE OR REPLACE FUNCTION public.geotab_rule_email_fn(
	vgeotabruleid bigint)
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
			SELECT E.Email
			FROM Email AS E
			INNER JOIN emailbygeotabrule AS egr
			ON E.Id = egr.Id_mail
			WHERE egr.id_geotabruleserial = vGeotabRuleId
			ORDER BY E.email ASC
		) AS dt), '[]'::JSON
	);
END
$BODY$;

ALTER FUNCTION public.geotab_rule_email_fn(bigint)
    OWNER TO mmcam_dev;
