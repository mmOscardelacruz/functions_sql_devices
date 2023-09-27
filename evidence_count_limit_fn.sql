-- FUNCTION: public.evidence_count_limit_fn(json, integer)

-- DROP FUNCTION IF EXISTS public.evidence_count_limit_fn(json, integer);

CREATE OR REPLACE FUNCTION public.evidence_count_limit_fn(
	vvehicles json,
	voffset integer DEFAULT '-5'::integer)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$

DECLARE
	vFromDate		TIMESTAMP(0);
	vToDate			TIMESTAMP(0);
	vConfig			evidence_configuration;
	vLocalTime		TIMESTAMP(0);
	vResponse		tpResponse;
	--BÚSUQEDA EN PARTICIONES
	vSearchingDates	TIMESTAMP(0)[];
	vCurrentDate	TIMESTAMP(0);
	vStreamaxQuery	TEXT[];
	vGeotabQuery	TEXT[];
	vCountStreamax	INT := 1;
	vCountGeotab	INT := 1;
	vFinalQuery		TEXT;
BEGIN
	--INICIALIZAR RESPUESTA
	vResponse.code := 200; vResponse.status := TRUE; vResponse.message := ''; vResponse.data := '[]'::JSON;
	--CONVERTIR A HORA LOCAL
	vLocalTime := NOW() - (vOffset * INTERVAL '-1H');
	--LLENAR LA CONFIGURACIÓN DE EVIDENCIAS
	vConfig := (SELECT dt FROM evidence_configuration AS dt LIMIT 1);
	--CALCULAR LA FECHA LIMITE SEGÚN EL MES ACTUAL
	vToDate := (TO_CHAR(vLocalTime, 'YYYY-MM-') || vConfig.cut_off_date_day || ' 00:00:00')::TIMESTAMP(0); --TOMAR COMO REFERENCIA EL DÍA 25 DEL MES ACTUAL
	vFromDate := vToDate - INTERVAL '1MONTH';
	IF(vLocalTime > vToDate) THEN
		--SI LA FECHA ACTUAL ESTÁ DESPUÉS DE LA FECHA DE CORTE, SE TOMA EL SIGUIENTE MES
		vFromDate := vToDate;
		vToDate := vToDate + INTERVAL '1MONTH' - INTERVAL '1S';
	END IF;
	/*UNA VEZ OBTENIDAS LAS FECHAS DE INCIO Y FIN, PROCEDER A CONTAR LOS VIDEOS DESCARGADOS POR VEHÍCULOS*/
	--INICIALIZAR LAS FECHAS DE BÚSQUEDA
	vSearchingDates := ARRAY[vFromDate, vToDate]::TIMESTAMP(0)[];
	vCurrentDate := vFromDate;
	--BUSCAR PARA STREAMAX Y GEOTAB
	WHILE (vCurrentDate <= vToDate) LOOP
		--SI EXISTE, GENERAR LA CONSULTA (STREAMAX)
		IF EXISTS (SELECT FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = 'receivedalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM')) THEN
			vStreamaxQuery[vCountStreamax] := 
			'
				SELECT id, gpstime, utc_time, type, idvehicle
				FROM receivedalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM') ||
				' WHERE gpstime BETWEEN ' || QUOTE_LITERAL(vFromDate) || ' AND ' || QUOTE_LITERAL(vToDate);
			vCountStreamax = vCountStreamax + 1;
		END IF;
		--SI EXISTE, GENERAR LA CONSULTA (GEOTAB)
		IF EXISTS (SELECT FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = 'geotabalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM')) THEN
			vGeotabQuery[vCountGeotab] := 
			'
				SELECT id_geotabalarm, gpstime, type, id_vehicle
				FROM geotabalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM') ||
				' WHERE gpstime BETWEEN ' || QUOTE_LITERAL(vFromDate) || ' AND ' || QUOTE_LITERAL(vToDate);
			vCountGeotab := vCountGeotab + 1;
		END IF;
		vCurrentDate := vCurrentDate + INTERVAL '1MONTH';
	END LOOP;
	--UNIFICAR BÚSQUEDAS
	--VERIFICAR SI HAY DE STREAMAX
	IF(ARRAY_LENGTH(vStreamaxQuery, 1) > 0) THEN
		vFinalQuery := 
		'
			SELECT v.id, v.serialmdvr, COUNT(*)::INT AS total
			FROM vehicle AS v
			INNER JOIN(' || ARRAY_TO_STRING(vStreamaxQuery, ' UNION ALL ') || ') AS ra
			ON v.id = ra.idvehicle
			INNER JOIN task_video_data AS tvd
			ON ra.id = tvd.id_alarm
			GROUP BY v.id, v.serialmdvr
		';
	END IF;
	--VERIFICAR SI HAY DE GEOTAB
	IF(ARRAY_LENGTH(vGeotabQuery, 1) > 0) THEN
		vFinalQuery := vFinalQuery ||
		'
			UNION ALL
			SELECT v.id, v.serialmdvr, COUNT(*)::INT AS total
			FROM vehicle AS v
			INNER JOIN ( ' || ARRAY_TO_STRING(vGeotabQuery, ' UNION ALL ') || ' ) AS ga
			ON v.id = ga.id_vehicle
			INNER JOIN task_video_data AS tvd
			ON ga.id_geotabalarm = tvd.id_geotabalarm
			GROUP BY v.id, v.serialmdvr
		';
	END IF;
	RAISE NOTICE 'From Date: %	| To Date: %', vFromDate, vToDate;
	RAISE NOTICE 'Final Query: %', vFinalQuery;
	
	IF(LENGTH(COALESCE(vFinalQuery, '')) > 0) THEN
		vFinalQuery := 
		'	SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
			FROM
			(
				SELECT dt.id AS "vehicleId", dt.serialmdvr AS "serialMDVR", dt.total AS "total",
				($1 - dt.total) AS "evidencesLeft",
				(SELECT range_color FROM evidence_configuration_detail WHERE evidence_range @> dt.total) AS color
				FROM ( ' || vFinalQuery || ' ) AS dt
			) AS dt ';
		EXECUTE vFinalQuery USING vConfig.video_count_limit INTO vResponse.data;
	ELSE
		vResponse.data := '[]';
	END IF;
	IF (vResponse.data IS NULL) THEN vResponse.data := '[]'; END IF;
	RAISE NOTICE 'Response.Data := %', vResponse.data;
	vResponse.data :=
	(vResponse.data::JSONB || 
	COALESCE((
		SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))::JSONB
		FROM
		(
			SELECT v.id AS "vehicleId", v.serialmdvr AS "serialMDVR",
			0 AS "total", vConfig.video_count_limit AS "evidencesLeft",
			(SELECT range_color FROM evidence_configuration_detail WHERE evidence_range @> 0) AS color
			FROM vehicle AS v
			WHERE v.serialmdvr NOT IN (SELECT dt->>'serialMDVR' FROM JSON_ARRAY_ELEMENTS(vResponse.data) AS dt)
		) AS dt
	), '[]'))::JSON;
	vResponse.data := COALESCE(vResponse.data, '[]'::JSON);
	RETURN TO_JSON(vResponse);
END
$BODY$;

ALTER FUNCTION public.evidence_count_limit_fn(json, integer)
    OWNER TO mmcam_dev;
