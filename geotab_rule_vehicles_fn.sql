-- FUNCTION: public.geotab_rule_vehicles_fn(bigint)

-- DROP FUNCTION IF EXISTS public.geotab_rule_vehicles_fn(bigint);

CREATE OR REPLACE FUNCTION public.geotab_rule_vehicles_fn(
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
			SELECT V.Id, V.Name, grv.onoffcams AS "onOffCams",
			geotab_rule_camera_select_fn(vGeotabRuleId, V.Id) AS "cameras"
			FROM Vehicle AS V
			INNER JOIN geotabRuleByVehicle AS grv
			ON V.Id = grv.Id_Vehicle
			WHERE grv.id_geotabruleserial = vGeotabRuleId
			ORDER BY V.Name ASC
		) AS dt), '[]'::JSON
	);
END
$BODY$;

ALTER FUNCTION public.geotab_rule_vehicles_fn(bigint)
    OWNER TO mmcam_dev;
