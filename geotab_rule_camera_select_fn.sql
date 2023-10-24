-- FUNCTION: public.geotab_rule_camera_select_fn(bigint, bigint)

-- DROP FUNCTION IF EXISTS public.geotab_rule_camera_select_fn(bigint, bigint);

CREATE OR REPLACE FUNCTION public.geotab_rule_camera_select_fn(
	vidgeotabruleserial bigint,
	vidvehicle bigint)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	RETURN
	(
		COALESCE ((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
				   FROM
				   (
					   SELECT ct.camera_type_id AS "cameraTypeId", ct.name,
					   c.channel
					   FROM GeotabRuleCamera AS gcr
					   INNER JOIN camera_type AS ct
					   ON gcr.camera_type_id = ct.camera_type_id
					   INNER JOIN camera AS c
					   ON ct.camera_type_id = c.camera_type_id
					   WHERE gcr.id_geotabruleserial = vIdGeotabRuleSerial
					   AND c.idVehicle = vIdVehicle
				   )AS dt), '[]'::JSON)
	);
END
$BODY$;

ALTER FUNCTION public.geotab_rule_camera_select_fn(bigint, bigint)
    OWNER TO mmcam_dev;
