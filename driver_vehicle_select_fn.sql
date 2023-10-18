-- FUNCTION: public.driver_vehicle_select_fn(integer)

-- DROP FUNCTION IF EXISTS public.driver_vehicle_select_fn(integer);

CREATE OR REPLACE FUNCTION public.driver_vehicle_select_fn(
	vdriverid integer)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	RETURN COALESCE(ARRAY_TO_JSON
	(
		(SELECT ARRAY_AGG(dt)
		FROM
		(
			SELECT v.Id AS "id", v.platenumber AS "plate",
			vd.serial AS "serialMDVR", v.vin, v.name, v.comments,  -- Aquí se cambió v.serialMDVR por vd.serial
			getCamerasByVehicle(v.Id, 2) AS cameras
			FROM vehicle AS v
			INNER JOIN farec.driver_vehicle AS dv
			ON v.Id = dv.vehicle_id
			-- Cambio: INNER JOIN con vehicle_device
			INNER JOIN vehicle_device AS vd
			ON v.Id = vd.vehicle_id
			WHERE dv.driver_id = vDriverId
		) AS dt)
	), '[]'::JSON);
END
$BODY$;

ALTER FUNCTION public.driver_vehicle_select_fn(integer)
    OWNER TO mmcam_dev;
