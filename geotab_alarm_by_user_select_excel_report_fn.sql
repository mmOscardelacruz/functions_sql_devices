-- FUNCTION: public.geotab_alarm_by_user_select_excel_report_fn(character varying, timestamp without time zone, timestamp without time zone, json, json, integer)

-- DROP FUNCTION IF EXISTS public.geotab_alarm_by_user_select_excel_report_fn(character varying, timestamp without time zone, timestamp without time zone, json, json, integer);

CREATE OR REPLACE FUNCTION public.geotab_alarm_by_user_select_excel_report_fn(
	vtoken character varying,
	vstarttime timestamp without time zone,
	vendtime timestamp without time zone,
	vrules json DEFAULT '[]'::json,
	vvehicles json DEFAULT '[]'::json,
	voffset integer DEFAULT '-6'::integer)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vResult 		tpResponse;
	vIdUser			BIGINT;
	vUserLng		INT;
	vRulesArr		BIGINT[];
	vVehiclesArr	BIGINT[];
	vGroups			BIGINT[];
	vOffsetInt		INTERVAL;
BEGIN
	vIdUser := checkValidToken(vToken);
	--OBTENER EL IDIOMA DEL USUARIO
	vUserLng := (SELECT language_id FROM userconfig WHERE IdUser = vIdUser);
	
	IF (JSON_ARRAY_LENGTH(COALESCE(vRules, '[]'::JSON)) <= 0) THEN 
		--SI EL USUARIO NO SELECCIONA REGLAS, ENTONCES AGARRAR LOS GRUPOS A LOS QUE TIENE ACCESO
		vGroups := getPlainGroupsAll(vIdUser);--getPlainGroups((SELECT IdFleet FROM "user" WHERE Id = vIdUser));
		--OBTENER LAS REGLAS QUE EXISTAN EN ESOS GRUPOS
		vRulesArr := (SELECT ARRAY_AGG(DISTINCT gr.id_geotabruleserial) 
				   FROM geotabRule AS gr
				   INNER JOIN geotabRuleByGroup AS grbg
				   ON gr.id_geotabruleserial = grbg.id_geotabruleserial
				   WHERE grbg.id_fleet IN (SELECT * FROM UNNEST(vGroups)));
	ELSE
		--EN CASO DE ENVIAR REGLAS, TOMAR LOS GRUPOS DIRECTAMENTE DE ELLAS Y A SUS GRUPOS HIJOS
		vRulesArr := (SELECT REPLACE(dt::TEXT, '"', '') FROM JSON_ARRAY_ELEMENTS(vRules) AS dt);
		vGroups := getChildGroups((SELECT ARRAY_AGG(DISTINCT id_fleet) FROM GeotabRuleByGroup WHERE id_geotabruleserial IN (SELECT * FROM UNNEST(vRulesArr))));
	END IF;
	--SI LOS ARREGLOS DE VEHÍCULOS VIENEN NULOS
	IF (JSON_ARRAY_LENGTH(COALESCE(vVehicles, '[]'::JSON)) <= 0) THEN --LLENAR SUS DATOS CON LOS GRUPOS QUE YA SE OBTUVIERON
		vVehiclesArr := (SELECT ARRAY_AGG(V.Id) FROM Vehicle AS V WHERE v.IdFleet IN (SELECT * FROM UNNEST(vGroups))); 
	ELSE --EN CASO CONTRARIO, LLENAR EL ARREGLO NATIVO
		vVehiclesArr := (SELECT ARRAY_AGG(DISTINCT REPLACE(dt::TEXT, '"', '')) FROM JSON_ARRAY_ELEMENTS(vVehicles) AS dt);
	END IF;
	--EN CASO DE EXISTIR REGLAS POR VEHÍCULOS, OBTENER SUS IDs
	vVehiclesArr := vVehiclesArr || (SELECT ARRAY_AGG(grbv.id_vehicle) FROM geotabrulebyvehicle AS grbv WHERE id_geotabruleserial IN (SELECT * FROM UNNEST(vRulesArr)));
	--QUITAR POSIBLES DATOS REPETIDOS
	vVehiclesArr := (SELECT ARRAY_AGG(DISTINCT dt) FROM UNNEST(vVehiclesArr) AS dt);
	
	--CONVERTIR EN UN OFFSET UTILIZABLE PARA FECHAS:
	vOffsetInt := (INTERVAL '1H' * vOffset);
	IF (vStartTime IS NULL) THEN 
		vStartTime := (TO_CHAR((NOW() - vOffsetInt), 'YYYY-MM-DD ') || '00:00:00')::TIMESTAMP(0);
	ELSE --SE CONVIERTE EN UTC
		vStartTime := vStartTime - vOffsetInt;
	END IF;
	IF (vEndTime IS NULL) THEN
		vEndTime := (TO_CHAR((NOW() - vOffsetInt), 'YYYY-MM-DD ') || '23:59:59')::TIMESTAMP(0);
	ELSE --SE CONVIERTE EN UTC
		vEndTime := vEndTime - vOffsetInt;
	END IF;
	/* TESTING
	RAISE NOTICE 'Datos a Enviar: -----';
	RAISE NOTICE 'Offset: %', vOffsetInt;
	RAISE NOTICE 'Rules: %', vRulesArr;
	RAISE NOTICE 'Vehicles: %', vVehiclesArr;
	RAISE NOTICE 'From Date: %	| To Date: %', vStartTime, vEndTime; */
	--REGRESAR RESULTADOS:
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	vResult.data := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
							 FROM
							 (
								 SELECT dt.*, geotab_historical_attend_alarms_fn(dt."idNotify", vOffsetInt) AS "historicalAttends",
								geotab_historical_classification_alarms_fn(dt."idNotify", vOffsetInt) AS "historicalClassification"
								FROM
								(
									SELECT ga.Id_geotabalarm AS "idNotify", v.Id AS "idVehicle",
									--v.serialMdvr AS "serialMDVR",
									--Change replaced v.serialMdvr with vd.serial
									vd.serial AS "serialMDVR",
									v.VIN,
								 	v.name AS "eco",
									ga.gpslat AS "latitude", ga.gpslng AS "longitude", ga.gpsTime::TIMESTAMP(0) + vOffsetInt  AS "dateTime", 
									CASE WHEN (SELECT MIN(date_attended) FROM attendgeotabalarm WHERE id_geotabalarm = ga.id_geotabalarm) IS NULL THEN FALSE ELSE TRUE END AS attended,
								 	(select id_user from attendGeotabAlarm where id_geotabAlarm = ga.id_geotabalarm FETCH FIRST 1 ROWS ONLY) as "IdUser",
									gr.name AS "ruleName", gr.is_popup AS "isPopup", gr.is_email AS "isEmail", 
									gr.id_geotabruleserial AS "idRule", gr.video_required AS "videoRequired", ac.alarm_category_id AS "alarmCategoryId", 
									CASE WHEN act.name IS NULL THEN ac.name ELSE act.name END AS category, ac.value AS "alarmColor",
									CASE WHEN EXISTS(SELECT * FROM geotab_alarm_link WHERE Id_geotabalarm = ga.Id_geotabalarm) THEN TRUE ELSE FALSE END AS "hasData",
									CASE WHEN (SELECT MIN(date_attended) FROM attendgeotabalarm WHERE id_geotabalarm = ga.id_geotabalarm) IS NULL THEN FALSE ELSE TRUE END AS "isPopupAt",
									(SELECT MIN(date_attended) + vOffsetInt FROM attendgeotabalarm WHERE id_geotabalarm = ga.id_geotabalarm) AS "attendedTime",
									CASE WHEN (SELECT MIN(date_sent_email) FROM attendgeotabalarm WHERE id_geotabalarm = ga.id_geotabalarm) IS NULL THEN FALSE ELSE TRUE END AS "isEmailAt",
									geotab_alarm_attender_fn(ga.id_geotabalarm, vOffsetInt) AS "attendedBy"
									FROM geotabalarm AS ga
									INNER JOIN geotabrule AS gr
									ON ga.id_geotabruleserial = gr.id_geotabruleserial
									INNER JOIN vehicle AS v
									ON ga.id_vehicle = v.Id
									--Agregar vehicle_device
									INNER JOIN vehicle_device AS vd
									ON vd.vehicle_id = v.Id
									LEFT JOIN attendgeotabalarm AS aga
									ON ga.id_geotabalarm = aga.id_geotabalarm
									LEFT JOIN rule_geotab_category AS rgc
									ON gr.id_geotabruleserial = rgc.geotab_rule_id
									LEFT JOIN alarm_category AS ac
									ON rgc.alarm_category_id = ac.alarm_category_id
									LEFT JOIN alarm_category_trans AS act
									ON ac.alarm_category_id = act.alarm_category_id 
									AND act.language_id = vUserLng
									WHERE gr.id_geotabruleserial IN (SELECT * FROM UNNEST(vRulesArr))
									AND v.Id IN (SELECT * FROM UNNEST(vVehiclesArr))
									AND ga.gpsTime BETWEEN vStartTime AND vEndTime
									GROUP BY ga.id_geotabalarm, v.id, v.serialmdvr, v.vin, ga.gpslat, ga.gpslng, ga.gpstime, gr.name, 
									gr.is_popup, gr.is_email, gr.id_geotabruleserial, gr.video_required, ac.alarm_category_id,
									act.name, ac.name, ac.value, v.name
								) AS dt
							 ) AS dt), '[]'::JSON);
	
	RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.geotab_alarm_by_user_select_excel_report_fn(character varying, timestamp without time zone, timestamp without time zone, json, json, integer)
    OWNER TO mmcam_dev;
