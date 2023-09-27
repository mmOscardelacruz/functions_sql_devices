-- FUNCTION: public.dashboard_resume(character varying, timestamp without time zone, timestamp without time zone, integer)

-- DROP FUNCTION IF EXISTS public.dashboard_resume(character varying, timestamp without time zone, timestamp without time zone, integer);

CREATE OR REPLACE FUNCTION public.dashboard_resume(
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
	vCurrentDate	TIMESTAMP(0);
	vQuery			VARCHAR := '';
	vQueries		VARCHAR[];
	vCount			INT := 1;
	--------------------------
	vResult 		tpResponse;
    vUserId			BIGINT;
  	vUserLng 		INT;
  	vVehiclesArr	BIGINT[];
	vRulesArr 		BIGINT[];
	vOffsetInt		INTERVAL;
BEGIN
	vUserId := checkValidToken(vToken);
    vUserLng := (SELECT language_id FROM userconfig WHERE IdUser = vUserId);
	vStartDate := vStartDate + (INTERVAL '-1H' * vOffset);
	vEndDate := vEndDate + (INTERVAL '-1H' * vOffset);
	vOffsetInt := COALESCE(vOffset, -6) * INTERVAL '-1H';
	RAISE NOTICE 'start: %', vStartDate;
	RAISE NOTICE 'end: %', vEndDate;
    IF( vStartDate IS null OR vEndDate IS null) THEN
       RAISE EXCEPTION '%', message_select_fn(15,3,vUserLng, 1, '{}'::VARCHAR[]);
    END IF;
    IF(vStartDate > vEndDate) THEN
       RAISE EXCEPTION '%', message_select_fn(15,3,vUserLng, 3, '{}'::VARCHAR[]);
    END IF;
	/*CONSULTAS DINÁMICAS STREAMAX Y GEOTAB*/
	vCurrentDate := (TO_CHAR(vStartDate, 'YYYY-MM') || '-01 00:00:00')::TIMESTAMP(0);
	WHILE (vCurrentDate <= vEndDate) LOOP
		IF EXISTS (SELECT FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = 'receivedalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM')) THEN
			vQueries[vCount] := 'SELECT ra.id, ra.driver_id, ac.alarm_category_id, ac.name, v.serialmdvr AS serial,
								CASE WHEN classification.streamax_alarm_id IS NULL THEN FALSE ELSE TRUE END AS "classificated",
								verificated."isVerificated" AS "verificated",
								CASE WHEN attend_status.attended_time IS NULL THEN FALSE ELSE TRUE END AS "attended"
								FROM receivedalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM') || ' AS ra
								INNER JOIN 
								(
									SELECT v.id, v.serialmdvr, v.name, v.vin,
									UNNEST(group_parents_branch_fn(v.idfleet)) AS idfleet
									FROM vehicle AS v
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
								LEFT JOIN 
								(
									SELECT DISTINCT streamax_alarm_id FROM classification_streamax
								) AS classification
								ON classification.streamax_alarm_id = ra.id
								LEFT JOIN
								(
									SELECT DISTINCT ra.id AS alarm_id,
									CASE WHEN hsac.id_streamaxalarm IS NULL THEN FALSE ELSE TRUE END AS "isVerificated"
									FROM historical_streamax_alarm_classification AS hsac
									RIGHT JOIN receivedalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM') || ' AS ra
									ON hsac.id_streamaxalarm = ra.id
									WHERE ra.utc_time BETWEEN ' || QUOTE_LITERAL(vStartDate) || ' AND ' || QUOTE_LITERAL(vEndDate) || '  
								) AS verificated
								ON ra.id = verificated.alarm_id
								LEFT JOIN
								(
									SELECT sr.idreceivedalarm AS id_alarm, MIN(sr.popupRTime) AS attended_time
									FROM sendrule AS sr
									INNER JOIN receivedalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM') || ' AS ra
									ON sr.idreceivedalarm = ra.id
									WHERE ra.utc_time BETWEEN ' || QUOTE_LITERAL(vStartDate) || ' AND ' || QUOTE_LITERAL(vEndDate) || ' 
									GROUP BY idreceivedalarm
								) AS attend_status
								ON ra.id = attend_status.id_alarm
								WHERE 
								(rules_by_group.idfleet = v.idfleet OR v.id = rules_by_group.idvehicle) 
								AND ra.utc_time BETWEEN ' || QUOTE_LITERAL(vStartDate) || ' AND ' || QUOTE_LITERAL(vEndDate);
			vCount := vCount + 1;
		END IF;
		
		IF EXISTS (SELECT FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = 'geotabalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM')) THEN
			vQueries[vCount] := 'SELECT ga.id_geotabalarm AS id, ga.geotab_id_driver AS driver_id, ac.alarm_category_id,
								ac.name, v.serialmdvr AS serial,
								CASE WHEN classification.alarm_id IS NULL THEN FALSE ELSE TRUE END AS "classificated",
								CASE WHEN verificated.id_alarm IS NULL THEN FALSE ELSE TRUE END AS "verificated",
								CASE WHEN attended.date_attended IS NULL THEN FALSE ELSE TRUE END AS "attended"
								FROM geotabalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM') || ' AS ga
								INNER JOIN geotabrule AS gr
								ON ga.id_geotabruleserial = gr.id_geotabruleserial
								INNER JOIN vehicle AS v
								ON v.id = ga.id_vehicle
								INNER JOIN rule_geotab_category AS rgc
								ON gr.id_geotabruleserial = rgc.geotab_rule_id
								INNER JOIN alarm_category AS ac
								ON rgc.alarm_category_id = ac.alarm_category_id
								LEFT JOIN 
								(
									SELECT DISTINCT id_geotabalarm AS alarm_id FROM classification
								) AS classification
								ON classification.alarm_id = ga.id_geotabalarm
								LEFT JOIN 
								(
									SELECT hgac.id_geotabalarm AS id_alarm
									FROM historical_geotab_alarm_classification AS hgac
									INNER JOIN geotabalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM') || ' AS ga
									ON hgac.id_geotabalarm = ga.id_geotabalarm
									WHERE ga.gpstime BETWEEN ' || QUOTE_LITERAL(vStartDate) || ' AND ' || QUOTE_LITERAL(vEndDate) || ' 
									GROUP BY hgac.id_geotabalarm
								) AS verificated
								ON verificated.id_alarm = ga.id_geotabalarm
								LEFT JOIN
								(
									SELECT aga.id_geotabalarm AS id_alarm, MIN(date_attended) AS date_attended
									FROM attendgeotabalarm AS aga
									INNER JOIN geotabalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM') || ' AS ga
									ON aga.id_geotabalarm = ga.id_geotabalarm
									WHERE ga.gpstime BETWEEN ' || QUOTE_LITERAL(vStartDate) || ' AND ' || QUOTE_LITERAL(vEndDate) || ' 
									GROUP BY aga.id_geotabalarm
								) AS attended
								ON attended.id_alarm = ga.id_geotabalarm
								WHERE ga.gpstime BETWEEN ' || QUOTE_LITERAL(vStartDate) || ' AND ' || QUOTE_LITERAL(vEndDate);
			vCount := vCount + 1;
		END IF;
		vCurrentDate := vCurrentDate + INTERVAL '1 Month';
	END LOOP;
	vQuery := ARRAY_TO_STRING(vQueries, ' UNION ALL ');
	RAISE NOTICE '%', vQuery;
	IF (LENGTH(COALESCE(vQuery, '')) < 50) THEN
		vResult.status := FALSE; vResult.code := 404; vResult.message := 'No Info'; 
		vResult.data := JSON_BUILD_OBJECT('alerts', 0, 'vehicles', 0, 'drivers', 0, 'lowRisk', 0,
										   'mediumRisk', 0, 'highRisk', 0, 'noClassificated', 0,
										   'classificated', 0, 'verificated', 0, 'noVerificated', 0,
										   'attended', 0, 'noAttended', 0);
		RETURN TO_JSON(vResult);
	END IF;
	--REGRESAR LOS RESULTADOS
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	EXECUTE 'SELECT ROW_TO_JSON(dt)
			FROM
			(
				SELECT
				COALESCE(SUM(dt.total_alarm),0) AS "alerts",
				COALESCE(COUNT(DISTINCT dt.serial),0) AS "vehicles",
				COUNT(DISTINCT COALESCE(dt.driver_id, '|| QUOTE_LITERAL('') ||')) AS "drivers",
				COALESCE(SUM(CASE dt.alarm_category_id WHEN 1 THEN dt.total_alarm END),0) AS "lowRisk",
				COALESCE(SUM(CASE dt.alarm_category_id WHEN 2 THEN dt.total_alarm END),0) AS "mediumRisk",
				COALESCE(SUM(CASE dt.alarm_category_id WHEN 3 THEN dt.total_alarm END),0) AS "highRisk",
				COALESCE(SUM(CASE WHEN NOT dt.classificated THEN dt.total_alarm END),0) AS "noClassificated",
				COALESCE(SUM(CASE WHEN dt.classificated THEN dt.total_alarm END),0) AS "classificated",
				COALESCE(SUM(CASE WHEN NOT dt.verificated THEN dt.total_alarm END),0) AS "verificated",
				COALESCE(SUM(CASE WHEN dt.verificated THEN dt.total_alarm END),0) AS "noVerificated",
				COALESCE(SUM(CASE WHEN dt.attended THEN dt.total_alarm END),0) AS "attended",
				COALESCE(SUM(CASE WHEN NOT dt.attended THEN dt.total_alarm END),0) AS "noAttended"
				FROM
				(
					SELECT dt.driver_id, dt.alarm_category_id, dt.name, dt.serial, dt.classificated,
					dt.verificated, dt.attended, COUNT(*) AS total_alarm
					FROM( ' || vQuery || ' ) AS dt
					GROUP BY dt.driver_id, dt.alarm_category_id, dt.name, dt.serial, dt.classificated,
					dt.verificated, dt.attended
				) AS dt
			) AS dt' INTO vResult.data;
	RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.dashboard_resume(character varying, timestamp without time zone, timestamp without time zone, integer)
    OWNER TO mmcam_dev;
