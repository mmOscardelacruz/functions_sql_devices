-- FUNCTION: public.check_if_device_on(character varying, timestamp with time zone, timestamp with time zone)

-- DROP FUNCTION IF EXISTS public.check_if_device_on(character varying, timestamp with time zone, timestamp with time zone);

CREATE OR REPLACE FUNCTION public.check_if_device_on(
	vserialmdvr character varying,
	vfromdate timestamp with time zone,
	vtodate timestamp with time zone)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vIsDeviceOn BOOLEAN;
	vCurrentDate	TIMESTAMP(0);
	vQuery			VARCHAR := '';
	vQueries		VARCHAR[];
	vCount			INT := 1;
BEGIN
	IF (LENGTH(COALESCE(vSerialMDVR, ''))<= 0) THEN
		RAISE EXCEPTION 'Debe de enviar un serial para continuar';
	END IF;
	vCurrentDate := (TO_CHAR(vFromDate, 'YYYY-MM') || '-01 00:00:00')::TIMESTAMP(0);
	WHILE (vCurrentDate <= vToDate) LOOP
			IF EXISTS (SELECT FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = 'mdvr_connection_log_' || TO_CHAR(vCurrentDate, 'YYYY_MM')) THEN
				vQueries[vCount] := 'SELECT COUNT(*) FILTER (WHERE status) AS "on", COUNT(*) FILTER (WHERE NOT status) AS "off"
									FROM mdvr_connection_log_' || TO_CHAR(vCurrentDate, 'YYYY_MM') || ' 
									WHERE date_time BETWEEN ' || QUOTE_LITERAL(vFromDate) || ' AND '|| QUOTE_LITERAL(vToDate) || ' 
									AND serial_mdvr LIKE ' || QUOTE_LITERAL(vSerialMDVR);
				vCount := vCount + 1;
			END IF;
			vCurrentDate := vCurrentDate + INTERVAL '1 MONTH';
			--RAISE NOTICE '%', vQueries[vCount - 1];
		END LOOP;
	vQuery := ARRAY_TO_STRING(vQueries, ' UNION ALL ');
	RAISE NOTICE '%', vQuery;
	IF (LENGTH(COALESCE(vQuery, '')) < 50) THEN
		RAISE EXCEPTION 'No se encontró información en el periodo de búsqueda (Desde: %, Hasta: %)', vFromDate, vToDate;
	END IF;
	EXECUTE 'SELECT SUM("on") > SUM("off") 
			 FROM
			 ( '
				|| vQuery ||
			 ' ) AS dt' INTO vIsDeviceOn;
	RETURN vIsDeviceOn;
	/*
	RETURN
	(
		(SELECT COUNT(*) FROM mdvr_connection_log WHERE serial_mdvr LIKE vSerialMDVR AND date_time BETWEEN vFromDate AND vToDate AND Status) >
		(SELECT COUNT(*) FROM mdvr_connection_log WHERE serial_mdvr LIKE vSerialMDVR AND date_time BETWEEN vFromDate AND vToDate AND NOT Status)
	);*/
END
$BODY$;

ALTER FUNCTION public.check_if_device_on(character varying, timestamp with time zone, timestamp with time zone)
    OWNER TO mmcam_dev;
