-- FUNCTION: public.camera_access_insert_fn(json)

-- DROP FUNCTION IF EXISTS public.camera_access_insert_fn(json);

CREATE OR REPLACE FUNCTION public.camera_access_insert_fn(
	vdata json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vResult tpResponse;
BEGIN
	IF (JSON_ARRAY_LENGTH(COALESCE(vData, '[]'::JSON))<= 0) THEN
		vResult.code := 400; vResult.status := FALSE; vResult.message := 'Debe de insertar por lo menos un acceso';
		vResult.data := '[]'::JSON;
		RETURN TO_JSON(vResult.data);
	END IF;
	--INSERTAR LOS DATOS
	INSERT INTO camera_access (username, serial_mdvr, chnl, date_time)
	SELECT dt->>'mail', dt->>'serialMdvr', 
	(dt->>'chnl')::INT, NOW() FROM JSON_ARRAY_ELEMENTS(vData) AS dt
	ON CONFLICT ON CONSTRAINT camera_access_un
	DO 
	UPDATE SET date_time = NOW();
	--REGRESAR LOS VALORES INSERTADOS CON LA FECHA
	vResult.code := 200; vResult.status := TRUE;
	vResult.data := (SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
			 FROM
			 (
				 SELECT username AS "mail", serial_mdvr AS "serialMdvr", 
				 chnl, date_time AS "dateTime"
				 FROM camera_access
				 WHERE serial_mdvr IN (SELECT dt->>'serialMdvr' FROM JSON_ARRAY_ELEMENTS(vData) AS dt)
				 AND chnl IN (SELECT (dt->>'chnl')::INT FROM JSON_ARRAY_ELEMENTS(vData) AS dt)
			 )AS dt);
	RETURN TO_JSON(vResult);
END
$BODY$;
