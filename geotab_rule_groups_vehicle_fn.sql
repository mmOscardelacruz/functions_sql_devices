-- FUNCTION: public.geotab_rule_groups_vehicle_fn(bigint, boolean, bigint)

-- DROP FUNCTION IF EXISTS public.geotab_rule_groups_vehicle_fn(bigint, boolean, bigint);

CREATE OR REPLACE FUNCTION public.geotab_rule_groups_vehicle_fn(
	vgroupid bigint,
	vonoffcams boolean,
	vgeotabruleid bigint)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
 
BEGIN
	RETURN 
	(
		COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
				 FROM
				 (
					 SELECT V.Id, V.name, vOnOffCams AS "onOffCams",
					 geotab_rule_camera_select_fn(vGeotabRuleId, v.Id) AS "cameras"
					 FROM Vehicle AS V
					 WHERE v.IdFleet = vGroupId
				 ) AS dt), '[]'::JSON)
	);
END
$BODY$;

ALTER FUNCTION public.geotab_rule_groups_vehicle_fn(bigint, boolean, bigint)
    OWNER TO mmcam_dev;
