-- FUNCTION: public.camera_access_delete_fn(json)

-- DROP FUNCTION IF EXISTS public.camera_access_delete_fn(json);

CREATE OR REPLACE FUNCTION public.camera_access_delete_fn(
	vdata json)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	IF (JSON_ARRAY_LENGTH(COALESCE(vData, '[]'::JSON))<= 0) THEN
		RAISE EXCEPTION 'El arreglo debe de contener por lo menos un elemento a eliminar';
	END IF;
	/*
	DELETE FROM camera_access
	USING JSON_ARRAY_ELEMENTS(vData) AS dt
	WHERE camera_access.serial_mdvr LIKE dt->>'serialMDVR'
	AND camera_access.user_id = (dt->>'userId')::BIGINT
	AND camera_access.chnl = (dt->>'chnl')::INT;*/
	DELETE FROM camera_access
	WHERE 
	serial_mdvr IN (SELECT dt->>'serialMdvr' FROM JSON_ARRAY_ELEMENTS(vData) AS dt) AND
	username IN (SELECT dt->>'mail' FROM JSON_ARRAY_ELEMENTS(vData) AS dt) AND
	chnl IN (SELECT (dt->>'chnl')::INT FROM JSON_ARRAY_ELEMENTS(vData) AS dt);
END
$BODY$;

