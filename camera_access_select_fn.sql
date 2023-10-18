-- FUNCTION: public.camera_access_select_fn(timestamp without time zone, timestamp without time zone, json, boolean)

-- DROP FUNCTION IF EXISTS public.camera_access_select_fn(timestamp without time zone, timestamp without time zone, json, boolean);

CREATE OR REPLACE FUNCTION public.camera_access_select_fn(
	vfromdate timestamp without time zone DEFAULT NULL::timestamp without time zone,
	vtodate timestamp without time zone DEFAULT NULL::timestamp without time zone,
	vserialmdvr json DEFAULT '[]'::json,
	visdetailed boolean DEFAULT false)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vResult tpResponse;
	vSerialArr VARCHAR[];
BEGIN
	vResult.code := 400; vResult.status := FALSE;
	vResult.data := '[]'::JSON;
	--VALIDACIONES
	IF (vFromDate IS NULL) THEN
		vFromDate := (SELECT MIN(date_time) FROM camera_access);
	END IF;
	IF (vToDate IS NULL) THEN
		vToDate := (SELECT MAX(date_time) + INTERVAL '1S' FROM camera_access);
	END IF;
	IF (vFromDate > vToDate) THEN
		vResult.message := 'La fecha de inicio no puede ser mayor a la fecha fin';
		RETURN TO_JSON(vResult);
	END IF;
	IF (JSON_ARRAY_LENGTH(COALESCE(vSerialMDVR, '[]'::JSON)) > 0) THEN
		vSerialArr := (SELECT ARRAY_AGG(DISTINCT REPLACE(dt::TEXT, '"', '')) FROM JSON_ARRAY_ELEMENTS(vSerialMDVR) AS dt);
	ELSE
		vSerialArr := (SELECT ARRAY_AGG(DISTINCT serial_mdvr) FROM camera_access);
	END IF;
	--REGRESAR LOS VALORES INSERTADOS CON LA FECHA
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	IF (NOT vIsDetailed) THEN
		--VISTA GENERAL
		vResult.data := (SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
					FROM
					(
						SELECT serial_mdvr AS "serialMdvr", 
						chnl, COUNT(*) AS "connections"
						FROM camera_access
						WHERE date_time BETWEEN vFromDate AND vToDate
						AND serial_mdvr IN (SELECT * FROM UNNEST(vSerialArr))
						GROUP BY serial_mdvr, chnl
					) AS dt);
	ELSE
		--VISTA DETALLADA
		vResult.data := (SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
					FROM
					(
						SELECT username AS "mail", serial_mdvr AS "serialMdvr", 
						chnl, date_time AS "dateTime"
						FROM camera_access
						WHERE date_time BETWEEN vFromDate AND vToDate
						AND serial_mdvr IN (SELECT * FROM UNNEST(vSerialArr)) 
					) AS dt);
	END IF;
	RETURN TO_JSON(vResult);
END
$BODY$;

