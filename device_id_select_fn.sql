-- FUNCTION: public.device_id_select_fn(json)

-- DROP FUNCTION IF EXISTS public.device_id_select_fn(json);

CREATE OR REPLACE FUNCTION public.device_id_select_fn(
	vdata json)
    RETURNS TABLE("idVehicle" bigint, "serialMDVR" text) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
	RETURN QUERY
	SELECT vd.vehicle_id AS "idVehicle", vd.serial AS "serialMDVR" 
	FROM vehicle_device AS vd
	WHERE vd.serial IN (SELECT REPLACE(dt::TEXT, '"', '') FROM JSON_ARRAY_ELEMENTS(vData) dt);
END
$BODY$;

ALTER FUNCTION public.device_id_select_fn(json)
    OWNER TO mmcam_dev;
