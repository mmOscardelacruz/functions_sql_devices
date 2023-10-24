-- FUNCTION: public.geotab_rule_vehicle_task_fn(bigint)

-- DROP FUNCTION IF EXISTS public.geotab_rule_vehicle_task_fn(bigint);

CREATE OR REPLACE FUNCTION public.geotab_rule_vehicle_task_fn(
	vgeotabruleid bigint)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vData JSON;
	vGroups	BIGINT[];
BEGIN
	IF EXISTS(SELECT * FROM geotabrulebyvehicle WHERE id_geotabruleserial = vGeotabRuleId) THEN
		vData := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
						 FROM
						 (
							 SELECT v.Id AS "vehicleId", vmg.geotab_go_id AS "geotabGoId",
							 grv.onoffcams AS "onOffRequired", v.serialMDVR AS "serialMDVR",
							 geotab_rule_camera_select_fn(vGeotabRuleId, v.Id) AS "cameras"
							 FROM geotabrulebyvehicle AS grv
							 INNER JOIN vehicle AS v
							 ON grv.id_vehicle = v.Id
							 INNER JOIN vehicle_mdvr_go AS vmg
							 ON v.Id = vmg.vehicle_id
							 WHERE grv.id_geotabruleserial = vGeotabRuleId
						 ) AS dt), '[]'::JSON);
	ELSE
		vGroups := getChildGroups((SELECT ARRAY_AGG(id_fleet) FROM geotabrulebygroup WHERE id_geotabruleserial = vGeotabRuleId));
		vData := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
							 FROM
							 (
								 SELECT v.Id AS "vehicleId", vmg.geotab_go_id AS "geotabGoId",
								 grbg.onoffcams AS "onOffRequired", v.SerialMDVR AS "serialMDVR",
								 geotab_rule_camera_select_fn(vGeotabRuleId, v.Id) AS "cameras"
								 FROM vehicle AS v
								 INNER JOIN vehicle_mdvr_go AS vmg
								 ON v.Id = vmg.vehicle_id
								 INNER JOIN geotabrulebygroup AS grbg
								 ON v.IdFleet IN (SELECT dt FROM UNNEST(vGroups) AS dt)
								 GROUP BY v.id, vmg.geotab_go_id, grbg.onoffcams
							 ) AS dt), '[]'::JSON);
	END IF;
	RETURN vData;
END
$BODY$;

ALTER FUNCTION public.geotab_rule_vehicle_task_fn(bigint)
    OWNER TO mmcam_dev;
