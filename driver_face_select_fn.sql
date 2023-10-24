-- FUNCTION: public.driver_face_select_fn(integer)

-- DROP FUNCTION IF EXISTS public.driver_face_select_fn(integer);

CREATE OR REPLACE FUNCTION public.driver_face_select_fn(
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
			SELECT face_id AS "faceId",
			autorized, path
			FROM farec.face
			WHERE driver_id = vDriverId
		) AS dt)
	), '[]'::JSON);
END
$BODY$;

ALTER FUNCTION public.driver_face_select_fn(integer)
    OWNER TO mmcam_dev;
