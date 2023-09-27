-- FUNCTION: public.entry_exit_rules_devices_fn()

-- DROP FUNCTION IF EXISTS public.entry_exit_rules_devices_fn();

CREATE OR REPLACE FUNCTION public.entry_exit_rules_devices_fn(
	)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vResponse tpResponse;
BEGIN
	vResponse.code := '200'; vResponse.status := TRUE; vResponse.message := '';
	vResponse.data :=
	COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
			  FROM
			  (
				  SELECT r.zone_restriction_id_entry AS "entryId", 
				  r.zone_restriction_id_exit AS "exitId",
				  ARRAY_TO_JSON((SELECT ARRAY_AGG(DISTINCT geotab_go_id) 
								 FROM vehicle_mdvr_go 
								 WHERE vehicle_id IN (SELECT (dt->>'id')::BIGINT FROM JSON_ARRAY_ELEMENTS(getRuleVehicles(r.id)) AS dt))) AS devices
				  FROM rule AS r
				  WHERE r.zone_restriction
				  UNION ALL
				  SELECT gr.zone_restriction_id_entry AS "entryId", 
				  gr.zone_restriction_id_exit AS "exitId",
				  ARRAY_TO_JSON((SELECT ARRAY_AGG(DISTINCT dt->>'geotabGoId') 
								 FROM JSON_ARRAY_ELEMENTS(geotab_rule_vehicle_task_fn(gr.id_geotabruleserial)) AS dt)) AS devices
				  FROM geotabrule AS gr
				  WHERE gr.zone_restriction
			  ) AS dt), '[]'::JSON);
	RETURN TO_JSON(vResponse);
END
$BODY$;

ALTER FUNCTION public.entry_exit_rules_devices_fn()
    OWNER TO mmcam_dev;
