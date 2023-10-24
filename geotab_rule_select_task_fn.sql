-- FUNCTION: public.geotab_rule_select_task_fn()

-- DROP FUNCTION IF EXISTS public.geotab_rule_select_task_fn();

CREATE OR REPLACE FUNCTION public.geotab_rule_select_task_fn(
	)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vResult tpResponse;
BEGIN
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	vResult.data := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
							 FROM
							 (
								 SELECT id_geotabruleserial AS "geotabRuleSerialId",
								 id_geotabrule AS "geotabRule", geotab_rule_vehicle_task_fn(id_geotabruleserial) AS "vehicles"
								 FROM geotabrule
							 ) AS dt), '[]'::JSON);
	RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.geotab_rule_select_task_fn()
    OWNER TO mmcam_dev;
