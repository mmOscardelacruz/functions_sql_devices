-- FUNCTION: public.geotab_rule_groups_fn(bigint)

-- DROP FUNCTION IF EXISTS public.geotab_rule_groups_fn(bigint);

CREATE OR REPLACE FUNCTION public.geotab_rule_groups_fn(
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
			SELECT F.Id, F.Name, grg.onoffcams AS "onOffCams",
			geotab_rule_groups_vehicle_fn(F.Id, grg.onoffcams, vGeotabRuleId) AS "vehicles"
			FROM Fleet AS F
			INNER JOIN geotabRuleByGroup AS grg
			ON F.Id = grg.id_fleet
			WHERE grg.id_geotabruleserial = vGeotabRuleId
			GROUP BY F.Id, F.Name, grg.onoffcams
			ORDER BY F.Name ASC
		) AS dt), '[]'::JSON
	);
END
$BODY$;

ALTER FUNCTION public.geotab_rule_groups_fn(bigint)
    OWNER TO mmcam_dev;
