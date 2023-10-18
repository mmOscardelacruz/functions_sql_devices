-- FUNCTION: public.advanced_report_select_fn(timestamp without time zone, timestamp without time zone, json, json, integer, integer, json)

-- DROP FUNCTION IF EXISTS public.advanced_report_select_fn(timestamp without time zone, timestamp without time zone, json, json, integer, integer, json);

CREATE OR REPLACE FUNCTION public.advanced_report_select_fn(
	vstarttime timestamp without time zone,
	vendtime timestamp without time zone,
	vvehicles json DEFAULT '[]'::json,
	vrules json DEFAULT '[]'::json,
	vlanguageid integer DEFAULT 2,
	voffset integer DEFAULT '-6'::integer,
	vdrivers json DEFAULT '[]'::json)
    RETURNS TABLE("serialMDVR" text, eco text, vin text, latitude double precision, longitude double precision, region text, "ruleName" text, "alarmName" text, "alarmTrans" text, "alarmCode" integer, datetime date, year integer, month integer, week text, date timestamp without time zone, "isAttended" text, "attendedTime" text, "attendedBy" text, "attendedJSON" text, "alarmCategory" character varying, classification text, "classificationDetails" text, "historicalAttends" text, "driverName" text, "errorMessage" character varying, groups json) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

DECLARE
	vVehiclesArr	BIGINT[];
	vRulesArr 		BIGINT[];
	vOffsetInt		INTERVAL;
	--------------------------------------
	vCurrentDate	TIMESTAMP(0);
	vQuery			VARCHAR := '';
	vQueries		VARCHAR[];
	vCount			INT := 1;
BEGIN
	--Cambio  en la consulta para obtener los vehiculos
	IF (JSON_ARRAY_LENGTH(COALESCE(vVehicles, '[]'::JSON)) <= 0) THEN
		vVehicles := (SELECT ARRAY_TO_JSON(ARRAY_AGG(vehicle_id)) FROM vehicle_device);
	END IF;
	IF (JSON_ARRAY_LENGTH(COALESCE(vRules, '[]'::JSON)) <= 0) THEN
		vRules := (SELECT ARRAY_TO_JSON(ARRAY_AGG(Id)) FROM rule);
	END IF;
	IF (JSON_ARRAY_LENGTH(COALESCE(vDrivers, '[]'::JSON)) <= 0) THEN
		vDrivers := (SELECT ARRAY_TO_JSON(ARRAY_AGG(DISTINCT COALESCE(driver_id, ''))) FROM receivedalarm);
	END IF;
	
	
	vVehiclesArr := (SELECT ARRAY_AGG(dt) FROM JSON_ARRAY_ELEMENTS(vVehicles) AS dt);
	vRulesArr := (SELECT ARRAY_AGG(dt) FROM JSON_ARRAY_ELEMENTS(vRules) AS dt);
	
	vStartTime := vStartTime + (INTERVAL '-1H' * vOffset);
	vEndTime := vEndTime + (INTERVAL '-1H' * vOffset);
	vOffsetInt := COALESCE(vOffset, -6) * INTERVAL '1H';
	
	RAISE NOTICE 'START %',vStartTime;
	RAISE NOTICE 'END %',vEndTime;
	RAISE NOTICE 'Drivers: %',vDrivers;
	
	
	/*CONSULTAS DINÁMICAS*/
	vCurrentDate := (TO_CHAR(vStartTime, 'YYYY-MM') || '-01 00:00:00')::TIMESTAMP(0);
	WHILE (vCurrentDate <= vEndTime) LOOP
		IF EXISTS (SELECT FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = 'receivedalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM')) THEN
			vQueries[vCount] := 'SELECT DISTINCT dt."idVehicle", dt."serialMDVR", dt.eco, dt.vin, dt.latitude, dt.longitude, dt."ruleName", dt."alarmName",
								dt."alarmTrans", dt."alarmCode", dt.datetime, dt."utcTime", dt."isPopupAt" AS "isAttended", 
								COALESCE(dt."attendedTime"::TIMESTAMP(0)::TEXT, '|| QUOTE_LITERAL('') || ') AS "attendedTime",
								COALESCE(dt."attendedBy", '|| QUOTE_LITERAL('Sin Atender') || ') AS "attendedBy", 
								dt."category" AS "alarmCategory", 
								(COALESCE(last_alert_attend, '|| QUOTE_LITERAL('{}') ||')::TEXT) AS "classificationDetails",
								(COALESCE(streamax_historical_attend_alarms, ' || QUOTE_LITERAL('[]') || ')::TEXT) AS "historicalAttends",
								(COALESCE(streamax_historical_classification,' || QUOTE_LITERAL('[]') || ')::TEXT) AS "historicalClassification",
								dt."driverName",
								COALESCE((CASE WHEN eet.message IS NULL THEN ee.message ELSE eet.message END), ' || QUOTE_LITERAL('') || ' ) AS "errorMessage"
								FROM
								(
										
									SELECT RA.Id AS "idNotify", V.Id AS "idVehicle", V.SerialMDVR AS "serialMDVR",
									V.name AS "eco",
									V.VIN, RA.GPSLat AS "latitude", RA.GPSLng AS "longitude", R.Name AS "ruleName",
									AD.Name AS "alarmName", AT.Description AS "alarmTrans", AD.Code AS "alarmCode",
									RA.GPSTime::TIMESTAMP(0) AS "datetime", RA.utc_time::TIMESTAMP(0) as "utcTime",
									COALESCE(getAttendStatus( 1 , R.Id, RA.Id), FALSE) AS "isPopupAt",
									(send_rule.popuprtime + '|| QUOTE_LITERAL(vOffsetInt) || ') AS "attendedTime",
									--COALESCE(SR.EmailR, FALSE) AS "isEmailAt",
									R.IsPopup AS "isPopup", R.IsEmail AS "isEmail", GetAlarmAttender(RA.Id, '|| QUOTE_LITERAL(vOffsetInt) || ')::TEXT AS "attendedBy", R.Id AS "idRule",
									R.video_required AS "videoRequired",
									ac.alarm_category_id AS "alarmCategoryId", CASE WHEN act.name IS NULL THEN ac.name ELSE act.name END AS category,
									ac.value AS "alarmColor", ra.alarm_id AS "streamaxId", ra.driver_name AS "driverName"
									FROM receivedalarm AS ra
									INNER JOIN 
									(
										--Obtener vehiculos y flotas de los vehiculos que se encuentran en la tabla vehicle_device
										SELECT vd.vehicle_id AS id, 
  												 vd.serial AS serialmdvr, 
   												 v.name, 
  												 v.VIN,
										UNNEST(group_parents_branch_fn(v.idfleet)) AS idfleet
										FROM vehicle_device AS vd
										INNER JOIN vehicle AS v ON vd.vehicle_id = v.id
									) AS v
									ON ra.idvehicle = v.id
									INNER JOIN 
									(
										SELECT sr.idreceivedalarm AS id_alarm, sr.idrule AS id_rule, 
										MAX(popuprtime) AS popuprtime, rbg.idfleet, rbv.idvehicle 
										FROM sendrule AS sr 
										INNER JOIN receivedalarm_'|| TO_CHAR(vCurrentDate, 'YYYY_MM') || ' AS ra 
										ON sr.idreceivedalarm = ra.id 
										INNER JOIN rule AS r 
										ON sr.idrule = r.id 
										LEFT JOIN rulebygroup AS rbg 
										ON r.id = rbg.idrule 
										LEFT JOIN rulebyvehicle AS rbv 
										ON r.id = rbv.idrule 
										WHERE ra.GPSTime BETWEEN ' || QUOTE_LITERAL(vStartTime) || ' AND ' || QUOTE_LITERAL(vEndTime)   || ' 
										GROUP BY sr.idreceivedalarm, sr.idrule, rbg.idfleet, rbv.idvehicle 
									) AS send_rule 
									ON send_rule.id_alarm = ra.id  
									INNER JOIN rule AS r 
									ON r.id = send_rule.id_rule 
									INNER JOIN alarmdata AS ad 
									ON r.idalarmdata = ad.id 
									INNER JOIN rule_category AS rc 
									ON r.id = rc.rule_id 
									INNER JOIN alarm_category AS ac 
									ON rc.alarm_category_id = ac.alarm_category_id 
									LEFT JOIN alarm_category_trans AS ACT 
									ON ac.alarm_category_id = act.alarm_category_id AND act.language_id = ' || vlanguageid  || ' 
									LEFT JOIN alarmtranslation AS AT 
									ON ad.id = at.idalarm AND at.idlanguage = ' || vlanguageid  || ' 
									WHERE R.Id IN (SELECT * FROM UNNEST(' || QUOTE_LITERAL('{'||(SELECT ARRAY_TO_STRING(vRulesArr, ',', NULL))||'}') || '::BIGINT[])) 
									AND V.Id IN (SELECT * FROM UNNEST( '  || QUOTE_LITERAL('{'||(SELECT ARRAY_TO_STRING(vVehiclesArr, ',', NULL))||'}') || '::BIGINT[])) 
									AND (RA.GPSTime BETWEEN ' || QUOTE_LITERAL(vStartTime) || ' AND ' || QUOTE_LITERAL(vEndTime)   || ')  
									AND COALESCE(RA.driver_id, '|| QUOTE_LITERAL('') || ') IN (SELECT REPLACE(dt::TEXT, ' || QUOTE_LITERAL('"') || ', ' || QUOTE_LITERAL('') || ') FROM JSON_ARRAY_ELEMENTS(' || QUOTE_LITERAL(vDrivers) || ') AS dt) 
									AND (send_rule.idfleet = v.idfleet OR v.id = send_rule.idvehicle)
									GROUP BY RA.GPSTime, RA.Id, V.Id, V.SerialMDVR, V.VIN, RA.GPSLat, RA.GPSLng, R.Name,
									AD.Name, AT.Description, AD.Code, R.IsPopup, R.IsEmail, R.Id, R.video_required,
									ac.alarm_category_id, act.name, ac.name, ac.value, v.name, ra.alarm_id, driver_name,
									send_rule.popuprtime
									ORDER BY RA.GPSTime DESC
								) AS dt
								LEFT JOIN streamax_download_task AS sdt
								ON sdt.id_received_alarm = dt."idNotify"
								LEFT JOIN evidence_error AS ee
								ON sdt.state = ee.state AND sdt.substate = ee.substate
								LEFT JOIN evidence_error_trans AS eet
								ON eet.evidence_error_id = ee.evidence_error_id AND eet.language_id = ' || vlanguageid  || ' 
								LEFT JOIN
								JSON_ARRAY_ELEMENTS((
									SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
									FROM
									(
										SELECT CASE WHEN cmt.classification_message IS NULL THEN cm.classification_message 
										ELSE cmt.classification_message END AS "classification",
										COALESCE(historical_streamax_alarm_classification.calification, FALSE) AS "isVerified",
										cs.comment, cs.classification_date + '|| QUOTE_LITERAL(vOffsetInt) || ' AS "classificationDate",
										cs.streamax_alarm_id AS "id"
										FROM classification_streamax AS cs
										LEFT JOIN classification_messages AS cm
										ON cs.classification_message_id = cm.id_classification_message
										LEFT JOIN classification_message_trans AS cmt
										ON cm.id_classification_message = cmt.id_classification_message AND cmt.language_id = ' || vlanguageid || ' 
										LEFT JOIN
										(
											SELECT id_streamaxalarm, MAX(date_time) AS date_time, BOOL_OR(calification) AS calification
											FROM historical_streamax_alarm_classification
											GROUP BY id_streamaxalarm
										) AS historical_streamax_alarm_classification
										ON historical_streamax_alarm_classification.id_streamaxalarm = cs.streamax_alarm_id
									) AS dt
								)) AS last_alert_attend
								ON (last_alert_attend->>' || QUOTE_LITERAL('id') || ')::BIGINT = dt."idNotify"
								LEFT JOIN
								JSON_ARRAY_ELEMENTS((
									SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
									FROM
									(
										SELECT dt.id, ARRAY_TO_JSON(ARRAY_AGG(dt)) AS "data"
										FROM
										(
											SELECT ra.id AS "id", u.name, u.lastname AS "lastName", u.username,
											sr.popuprtime + ' || QUOTE_LITERAL(vOffsetInt) || ' AS "attendedDateTime" 
											FROM sendrule AS sr
											INNER JOIN "user" AS u
											on sr.iduser = u.Id
											INNER JOIN receivedalarm AS RA
											ON sr.idReceivedAlarm = ra.id
											WHERE sr.popuprtime IS NOT NULL
											ORDER BY 5 DESC
										) AS dt
										GROUP BY dt.id
									) AS dt
								)) AS streamax_historical_attend_alarms
								ON (streamax_historical_attend_alarms->>' || QUOTE_LITERAL('id') || ')::BIGINT = dt."idNotify"
								LEFT JOIN
								JSON_ARRAY_ELEMENTS((
									SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
									FROM
									(
										SELECT dt."id", ARRAY_TO_JSON(ARRAY_AGG(dt)) AS "data"
										FROM
										(
											SELECT cs.streamax_alarm_id AS "id", u.name, u.lastname AS "lastName", u.username,
											cs.comment, cm.classification_message,
											cs.classification_date + ' || QUOTE_LITERAL(vOffsetInt) || ' AS "classificationDateTime"
											FROM classification_streamax AS cs
											INNER JOIN "user" AS u
											on cs.user_id = u.Id
											INNER JOIN classification_messages AS cm
											ON cs.classification_message_id = cm.id_classification_message
										) AS dt
										GROUP BY dt."id"
									) AS dt
								)) AS streamax_historical_classification
								ON (streamax_historical_classification->> ' || QUOTE_LITERAL('id') || ')::BIGINT = dt."idNotify"';
			vCount := vCount + 1;
		END IF;
		vCurrentDate := vCurrentDate + INTERVAL '1 MONTH';	
	END LOOP;
	vQuery := ARRAY_TO_STRING(vQueries, ' UNION ALL ');
	RAISE NOTICE '%', vQuery;
	IF (LENGTH(COALESCE(vQuery, '')) < 50) THEN
		RAISE EXCEPTION 'No se encontró información en el periodo de búsqueda (Desde: %, Hasta: %)', vStartTime, vEndTime;
	END IF;
	
	RETURN QUERY
	EXECUTE
	'SELECT dt."serialMDVR", dt.eco, dt.vin, dt.latitude, dt.longitude,
	CASE WHEN SPLIT_PART(dt."ruleName", ' || QUOTE_LITERAL('-') || ', 2) LIKE ' || QUOTE_LITERAL('') || ' THEN ' || QUOTE_LITERAL('Sin Información') || ' ELSE SPLIT_PART(dt."ruleName", ' || QUOTE_LITERAL('-') || ', 1) END, 
	dt."ruleName", dt."alarmName", COALESCE(dt."alarmTrans", ' || QUOTE_LITERAL('') || ' )::TEXT, dt."alarmCode", (dt."utcTime" + ' || QUOTE_LITERAL(vOffsetInt) || ')::DATE, EXTRACT(YEAR FROM (dt."utcTime" + ' || QUOTE_LITERAL(vOffsetInt) || '))::INT,
	EXTRACT(MONTH FROM (dt."utcTime" + ' || QUOTE_LITERAL(vOffsetInt) || '))::INT, '|| QUOTE_LITERAL('') ||'::TEXT AS week, (dt."utcTime" + ' || QUOTE_LITERAL(vOffsetInt) || '), CASE WHEN dt."isAttended" THEN ' || QUOTE_LITERAL('Atendido') || ' ELSE ' || QUOTE_LITERAL('Sin Atender') || ' END, dt."attendedTime",
	CASE WHEN dt."attendedBy" LIKE ' || QUOTE_LITERAL('%Sin Atender%') || ' THEN dt."attendedBy" ELSE dt."attendedBy"::JSON -> 0 ->> ' || QUOTE_LITERAL('username') || ' END,
	CASE WHEN dt."attendedBy" LIKE ' || QUOTE_LITERAL('%Sin Atender%') || ' THEN dt."attendedBy" ELSE dt."attendedBy" END,
	dt."alarmCategory" AS "Categoría", 
	CASE WHEN dt."classificationDetails"::JSON ->>' || QUOTE_LITERAL('classification') || ' IS NULL THEN ' || QUOTE_LITERAL('Sin Clasificar') || ' ELSE dt."classificationDetails"::JSON ->>' || QUOTE_LITERAL('classification') || ' END,
	dt."classificationDetails", dt."historicalAttends", COALESCE(dt."driverName", ' || QUOTE_LITERAL('No Driver') || ')::TEXT,
	dt."errorMessage",
	JSON_BUILD_ARRAY(groups.group) AS groups
	FROM(' || vQuery || ') AS dt
	INNER JOIN 
	(
		SELECT f.name AS "group", ARRAY_AGG(v.id) AS vehicles
		FROM vehicle AS v
		INNER JOIN fleet AS f
		ON v.idfleet = f.id
		GROUP BY f.name
	) AS groups
	ON dt."idVehicle" = ANY(groups.vehicles)';
END
$BODY$;

ALTER FUNCTION public.advanced_report_select_fn(timestamp without time zone, timestamp without time zone, json, json, integer, integer, json)
    OWNER TO mmcam_dev;
