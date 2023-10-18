-- FUNCTION: public.drivers_top_5_fn(character varying, timestamp without time zone, timestamp without time zone, integer)

-- DROP FUNCTION IF EXISTS public.drivers_top_5_fn(character varying, timestamp without time zone, timestamp without time zone, integer);

CREATE OR REPLACE FUNCTION public.drivers_top_5_fn(
	vtoken character varying,
	vstartdate timestamp without time zone,
	venddate timestamp without time zone,
	voffset integer DEFAULT '-5'::integer)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vResult		tpResponse;
	vUserId		BIGINT;
	vUserLng	INT;
	vRulesArr 	BIGINT[];
	vOffsetInt	INTERVAL;
	---------------------
	vCurrentDate	TIMESTAMP(0);
	vQuery			VARCHAR := '';
	vQueries		VARCHAR[];
	vCount			INT := 1;
BEGIN
	vUserId := checkValidToken(vToken);
    vUserLng := (SELECT language_id FROM userconfig WHERE IdUser = vUserId);
	
	vStartDate := vStartDate + (INTERVAL '-1H' * vOffset);
	vEndDate := vEndDate + (INTERVAL '-1H' * vOffset);
	vOffsetInt := COALESCE(vOffset, -6) * INTERVAL '-1H';
	
	RAISE NOTICE 'startdate %', vStartDate;
	RAISE NOTICE 'endDate %', vEndDate;
    IF( vStartDate IS NULL OR vEndDate IS NULL) THEN
       RAISE EXCEPTION '%', message_select_fn(15,3,vUserLng, 1, '{}'::VARCHAR[]);
    END IF;
    IF(vStartDate > vEndDate) THEN
       RAISE EXCEPTION '%', message_select_fn(15,3,vUserLng, 3, '{}'::VARCHAR[]);
    END IF;
	/*CONSULTAS DINÁMICAS*/
	vCurrentDate := (TO_CHAR(vStartDate, 'YYYY-MM') || '-01 00:00:00')::TIMESTAMP(0);
	WHILE (vCurrentDate <= vEndDate) LOOP
		IF EXISTS (SELECT FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = 'receivedalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM')) THEN
			vQueries[vCount] := 'SELECT ra.id, ra.driver_id, ra.driver_name,
								ac.alarm_category_id, ac.name
								FROM receivedalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM') || ' AS ra
								INNER JOIN 
								(
									-- Cambio aquí: seleccionamos el serial desde vd
									SELECT v.id, vd.serial AS serialmdvr, v.name, v.vin, 
									UNNEST(group_parents_branch_fn(v.idfleet)) AS idfleet
									FROM vehicle AS v
									INNER JOIN vehicle_device AS vd 
									ON v.id = vd.vehicle_id  -- Cambio aquí: JOIN con vehicle_device
								) AS v
								ON ra.idvehicle = v.id 
								INNER JOIN
								(
									SELECT sr.idreceivedalarm AS id_alarm, sr.idrule AS rule_id,
									rbg.idfleet, rbv.idvehicle
									FROM sendrule AS sr
									INNER JOIN receivedalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM') || ' AS ra
									ON sr.idreceivedalarm = ra.id
									INNER JOIN rule AS r
									ON sr.idrule = r.id
									LEFT JOIN rulebygroup AS rbg
									ON r.id = rbg.idrule
									LEFT JOIN rulebyvehicle AS rbv
									ON r.id = rbv.idrule
									WHERE ra.utc_time BETWEEN ' || QUOTE_LITERAL(vStartDate) || ' AND ' || QUOTE_LITERAL(vEndDate)   || ' 
									GROUP BY sr.idreceivedalarm, sr.idrule, rbg.idfleet, rbv.idvehicle
								) AS rules_by_group
								ON rules_by_group.id_alarm = ra.id
								INNER JOIN rule_category AS rc
								ON rules_by_group.rule_id = rc.rule_id
								INNER JOIN alarm_category AS ac
								ON rc.alarm_category_id = ac.alarm_category_id 
								WHERE (rules_by_group.idfleet = v.idfleet OR v.id = rules_by_group.idvehicle) 
								AND ra.utc_time BETWEEN ' || QUOTE_LITERAL(vStartDate) || ' AND ' || QUOTE_LITERAL(vEndDate);
			vCount := vCount + 1;
		END IF;
		
		IF EXISTS (SELECT FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = 'geotabalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM')) THEN
			vQueries[vCount] := 'SELECT ga.id_geotabalarm AS id, ga.geotab_id_driver, ga.geotab_driver_name,
								ac.alarm_category_id, ac.name
								FROM geotabalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM') || ' AS ga
								INNER JOIN geotabrule AS gr
								ON ga.id_geotabruleserial = gr.id_geotabruleserial
								INNER JOIN rule_geotab_category AS rgc
								ON gr.id_geotabruleserial = rgc.geotab_rule_id
								INNER JOIN alarm_category AS ac
								ON rgc.alarm_category_id = ac.alarm_category_id
								WHERE ga.gpstime BETWEEN ' || QUOTE_LITERAL(vStartDate) || ' AND ' || QUOTE_LITERAL(vEndDate);
			vCount := vCount + 1;
		END IF;
		vCurrentDate := vCurrentDate + INTERVAL '1 MONTH';
	END LOOP;
	vQuery := ARRAY_TO_STRING(vQueries, ' UNION ALL ');
	RAISE NOTICE '%', vQuery;
	IF (COALESCE(ARRAY_LENGTH(vQueries, 1), 0) <= 0) THEN
		vResult.status := FALSE; vResult.code := 404; vResult.message := 'No Info'; 
		vResult.data := '[]';
		RETURN TO_JSON(vResult);
	END IF;
	--REGRESAR LOS RESULTADOS
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	EXECUTE 'SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
			FROM
			(
				SELECT
				COALESCE(dt.driver_id, '|| QUOTE_LITERAL('UnknownDriver') ||') AS "driverId",
				COALESCE(dt.driver_name, ' || QUOTE_LITERAL('No Driver') || ') AS "driverName",
				COALESCE(SUM(dt.total_alarm), 0) AS "totalAlerts",
				COALESCE(SUM(CASE dt.alarm_category_id WHEN 1 THEN dt.total_alarm END),0) AS "lowRisk",
				COALESCE(SUM(CASE dt.alarm_category_id WHEN 2 THEN dt.total_alarm END),0) AS "mediumRisk",
				COALESCE(SUM(CASE dt.alarm_category_id WHEN 3 THEN dt.total_alarm END),0) AS "highRisk"
				FROM
				(
					SELECT dt.driver_id, dt.driver_name, dt.alarm_category_id, dt.name, COUNT(*) AS total_alarm
					FROM( ' || vQuery || ' ) AS dt
					GROUP BY dt.driver_id, dt.driver_name, dt.alarm_category_id, dt.name
				) AS dt
				GROUP BY dt.driver_id, dt.driver_name
				ORDER BY 3 DESC LIMIT 5
			) AS dt' INTO vResult.data;
	vResult.data := COALESCE(vResult.data, '[]'::JSON);
	RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.drivers_top_5_fn(character varying, timestamp without time zone, timestamp without time zone, integer)
    OWNER TO mmcam_dev;
