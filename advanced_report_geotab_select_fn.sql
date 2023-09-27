-- DROP FUNCTION IF EXISTS public.advanced_report_geotab_select_fn(timestamp without time zone, timestamp without time zone, json, json, integer, integer, json);

CREATE OR REPLACE FUNCTION public.advanced_report_geotab_select_fn(
	vstarttime timestamp without time zone,
	vendtime timestamp without time zone,
	vvehicles json DEFAULT '[]'::json,
	vrules json DEFAULT '[]'::json,
	vlanguageid integer DEFAULT 2,
	voffset integer DEFAULT '-6'::integer,
	vdrivers json DEFAULT '[]'::json)
    RETURNS TABLE("serialMDVR" text, eco text, vin text, latitude double precision, longitude double precision, region text, "ruleName" text, "alarmName" text, "alarmTrans" text, "alarmCode" text, datetime date, year integer, month integer, week text, date timestamp without time zone, "isAttended" text, "attendedTime" text, "attendedBy" text, "attendedJSON" text, "alarmCategory" character varying, classification text, "classificationDetails" text, "historicalAttends" text, "driverName" text, "errorMessage" character varying, groups json) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE
	vVehiclesArr	BIGINT[];
	vRulesArr 		BIGINT[];
	vOffsetInt		INTERVAL;
BEGIN
	IF (JSON_ARRAY_LENGTH(COALESCE(vVehicles, '[]'::JSON)) <= 0) THEN
		vVehicles := (SELECT ARRAY_TO_JSON(ARRAY_AGG(Id)) FROM vehicle);
	END IF;
	IF (JSON_ARRAY_LENGTH(COALESCE(vRules, '[]'::JSON)) <= 0) THEN
		vRules := (SELECT ARRAY_TO_JSON(ARRAY_AGG(id_geotabruleserial)) FROM geotabrule);
	END IF;
	IF (JSON_ARRAY_LENGTH(COALESCE(vDrivers, '[]'::JSON)) <= 0) THEN
		vDrivers := (SELECT ARRAY_TO_JSON(ARRAY_AGG(DISTINCT COALESCE(driver_id, ''))) FROM receivedalarm);
	END IF;
	
	vVehiclesArr := (SELECT ARRAY_AGG(dt) FROM JSON_ARRAY_ELEMENTS(vVehicles) AS dt);
	vRulesArr := (SELECT ARRAY_AGG(dt) FROM JSON_ARRAY_ELEMENTS(vRules) AS dt);
	
	vStartTime := vStartTime + (INTERVAL '-1H' * vOffset);
	vEndTime := vEndTime + (INTERVAL '-1H' * vOffset);
	vOffsetInt := COALESCE(vOffset, -6) * INTERVAL '1H';
	
	RAISE NOTICE 'Drivers: % | Rules: % | StartTime: % | EndTime: % | OffsetInt: % | Vehicles: %',vDrivers, vRules, vStartTime, vEndTime, vOffsetInt, vVehicles;
	RETURN QUERY
	SELECT dt."serialMDVR", dt.eco, dt.vin, dt.latitude, dt.longitude,
	CASE WHEN SPLIT_PART(dt."ruleName", '-', 2) LIKE '' THEN 'Sin Información' ELSE SPLIT_PART(dt."ruleName", '-', 1) END,
	dt."ruleName"::TEXT, dt."alarmName"::TEXT, COALESCE(dt."alarmTrans", '')::TEXT, dt."alarmCode"::TEXT, (dt."utcTime" + vOffsetInt)::DATE, EXTRACT(YEAR FROM (dt."utcTime" + vOffsetInt))::INT,
	EXTRACT(MONTH FROM (dt."utcTime" + vOffsetInt))::INT, ''::TEXT AS week, (dt."utcTime" + vOffsetInt), CASE WHEN dt."isAttended" THEN 'Atendido' ELSE 'Sin Atender' END, dt."attendedTime",
	CASE WHEN dt."attendedBy" LIKE '%[]%' THEN 'Sin Atender' ELSE dt."attendedBy"::JSON -> 0 ->> 'username' END,
	CASE WHEN dt."attendedBy" LIKE '%[]%' THEN 'Sin Atender' ELSE dt."attendedBy" END,
	dt."alarmCategory" AS "Categoría", 
	CASE WHEN dt."classificationDetails"::JSON ->>'classification' IS NULL THEN 'Sin Clasificar' ELSE dt."classificationDetails"::JSON ->>'classification' END,
	dt."classificationDetails", dt."historicalAttends", COALESCE(dt."driverName", 'No Driver')::TEXT,
	dt."errorMessage",
	JSON_BUILD_ARRAY(groups.group) AS "groups"
	FROM
	(
		SELECT DISTINCT dt."idVehicle", dt."serialMDVR", dt.eco, dt.vin, dt.latitude, dt.longitude, dt."ruleName", dt."alarmName",
		dt."alarmTrans", dt."alarmCode", dt."dateTime", dt."utcTime", dt."isPopupAt" AS "isAttended", COALESCE(dt."attendedTime"::TIMESTAMP(0)::TEXT, '') AS "attendedTime",
		COALESCE(dt."attendedBy", 'Sin Atender') AS "attendedBy", dt."category" AS "alarmCategory", 
		(geotab_last_alert_attend_detail_fn(dt."idNotify", vOffsetInt, 2)::TEXT) AS "classificationDetails",
		(geotab_historical_attend_alarms_fn(dt."idNotify", vOffsetInt)::TEXT) AS "historicalAttends",
		(geotab_historical_classification_alarms_fn(dt."idNotify", vOffsetInt )::TEXT) AS "historicalClassification",
		dt."driverName",
		COALESCE((CASE WHEN eet.message IS NULL THEN ee.message ELSE eet.message END), '' ) AS "errorMessage"
		FROM
		(
			SELECT ga.id_geotabalarm AS "idNotify", v.Id AS "idVehicle", v.serialMDVR AS "serialMDVR", v.name AS "eco", v.VIN,
				ga.gpslat AS "latitude", ga.gpslng AS "longitude", gr.name AS "ruleName", 
				gr.name AS "alarmName", gr.name AS "alarmTrans", gr.id_geotabrule AS "alarmCode", 
				(ga.gpstime + vOffsetInt) AS "dateTime", ga.gpstime AS "utcTime",
				CASE WHEN (SELECT MIN(date_attended) FROM attendgeotabalarm WHERE id_geotabalarm = ga.id_geotabalarm) IS NULL THEN FALSE ELSE TRUE END AS "isPopupAt",
				(SELECT date_attended + vOffsetInt FROM attendGeotabAlarm WHERE id_geotabalarm = ga.id_geotabalarm ORDER BY date_attended ASC LIMIT 1) AS "attendedTime",
				gr.is_popup AS "isPopup", gr.is_email AS "isEmail", geotab_alarm_attender_fn(ga.id_geotabalarm, vOffsetInt)::TEXT AS "attendedBy", gr.id_geotabruleserial AS "idRule",
				gr.video_required AS "videoRequired", 
				ac.alarm_category_id AS "alarmCategoryId", CASE WHEN act.name IS NULL THEN ac.name ELSE act.name END AS category,
				ac.value AS "alarmColor", ga.geotab_driver_name AS "driverName"
				FROM geotabalarm AS ga
				INNER JOIN vehicle AS v
				ON ga.id_vehicle = v.id
				INNER JOIN geotabrule AS gr
				ON ga.id_geotabruleserial = gr.id_geotabruleserial
				INNER JOIN rule_geotab_category AS rgc
				ON gr.id_geotabruleserial = rgc.geotab_rule_id
				INNER JOIN alarm_category AS ac
				ON rgc.alarm_category_id = ac.alarm_category_id
				LEFT JOIN alarm_category_trans AS act
				ON AC.alarm_category_id = ACT.alarm_category_id AND ACT.language_id = vLanguageId
				WHERE
				gr.id_geotabruleserial IN (SELECT * FROM UNNEST(vRulesArr))
				AND v.id IN (SELECT * FROM UNNEST(vVehiclesArr))
				AND ga.gpstime BETWEEN vStartTime AND vEndTime
				AND COALESCE(ga.geotab_driver_name, '') IN (SELECT REPLACE(dt::TEXT, '"', '') FROM JSON_ARRAY_ELEMENTS(vDrivers) AS dt)
				GROUP BY
				ga.id_geotabalarm, v.Id, v.serialMDVR, v.name, v.VIN, ga.gpslat, ga.gpslng, gr.name, 
				gr.name, gr.id_geotabrule, ga.gpstime, gr.is_popup, gr.is_email, gr.id_geotabruleserial, gr.video_required, 
				ac.alarm_category_id, act.name, ac.name, ac.value, ga.geotab_driver_name
		) AS dt
		LEFT JOIN geotab_download_task AS gdt
		ON dt."idNotify" = gdt.id_geotabalarm
		LEFT JOIN evidence_error AS ee
		ON gdt.state = ee.state AND gdt.substate = ee.substate
		LEFT JOIN evidence_error_trans AS eet
		ON eet.evidence_error_id = ee.evidence_error_id AND eet.language_id = vLanguageId
	) AS dt
	INNER JOIN 
	(
		SELECT f.name AS "group", ARRAY_AGG(v.id) AS vehicles
		FROM vehicle AS v
		INNER JOIN fleet AS f
		ON v.idfleet = f.id
		GROUP BY f.name
	) AS "groups"
	ON dt."idVehicle" = ANY(groups.vehicles);
END
$BODY$;