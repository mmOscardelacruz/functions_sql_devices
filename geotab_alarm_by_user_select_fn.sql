-- FUNCTION: public.geotab_alarm_by_user_select_fn(character varying, timestamp without time zone, timestamp without time zone, json, json, integer)

-- DROP FUNCTION IF EXISTS public.geotab_alarm_by_user_select_fn(character varying, timestamp without time zone, timestamp without time zone, json, json, integer);

CREATE OR REPLACE FUNCTION public.geotab_alarm_by_user_select_fn(
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
				vCurrentDate	TIMESTAMP(0);
				vQuery			VARCHAR := '';
				vQueries		VARCHAR[];
				vCount			INT := 1;
			BEGIN
				vIdUser := checkValidToken(vToken);
				--OBTENER EL IDIOMA DEL USUARIO
				vUserLng := (SELECT language_id FROM userconfig WHERE IdUser = vIdUser);
				
				IF (JSON_ARRAY_LENGTH(COALESCE(vRules, '[]'::JSON)) <= 0) THEN 
					--SI EL USUARIO NO SELECCIONA REGLAS, ENTONCES AGARRAR LOS GRUPOS A LOS QUE TIENE ACCESO
					--vGroups := getPlainGroupsAll(vIdUser);--getPlainGroups((SELECT IdFleet FROM "user" WHERE Id = vIdUser));
					--OBTENER LAS REGLAS QUE EXISTAN EN ESOS GRUPOS
					/*vRulesArr := (SELECT ARRAY_AGG(DISTINCT gr.id_geotabruleserial) 
									FROM geotabRule AS gr
									LEFT JOIN geotabRuleByGroup AS grbg
									ON gr.id_geotabruleserial = grbg.id_geotabruleserial AND grbg.id_fleet IN (SELECT * FROM UNNEST(vGroups))
									LEFT JOIN geotabRuleByVehicle AS grbv
									ON gr.id_geotabruleserial = grbv.id_geotabruleserial AND grbv.id_vehicle IN (SELECT Id FROM Vehicle WHERE IdFleet IN (SELECT * FROM UNNEST(vGroups))));*/
					vResult.code := 200; vResult.status := TRUE; vResult.message := 'No Rules';
					vResult.data := '[]'::JSON;
					RETURN TO_JSON(vResult);
				ELSE
					--EN CASO DE ENVIAR REGLAS, TOMAR LOS GRUPOS DIRECTAMENTE DE ELLAS Y A SUS GRUPOS HIJOS
					vRulesArr := (SELECT ARRAY_AGG(REPLACE(dt::TEXT, '"', '')) FROM JSON_ARRAY_ELEMENTS(vRules) AS dt);
					vGroups := getChildGroups((SELECT ARRAY_AGG(DISTINCT id_fleet) FROM GeotabRuleByGroup WHERE id_geotabruleserial IN (SELECT * FROM UNNEST(vRulesArr))));
				END IF;
				--EN CASO DE EXISTIR REGLAS POR VEHÍCULOS, OBTENER SUS IDs
				--vVehiclesArr := (SELECT ARRAY_AGG(grbv.id_vehicle) FROM geotabrulebyvehicle AS grbv WHERE id_geotabruleserial IN (SELECT * FROM UNNEST(vRulesArr)));
				--SI LOS ARREGLOS DE VEHÍCULOS VIENEN NULOS
				IF (JSON_ARRAY_LENGTH(COALESCE(vVehicles, '[]'::JSON)) <= 0) THEN --LLENAR SUS DATOS CON LOS GRUPOS QUE YA SE OBTUVIERON
					--vVehiclesArr := vVehiclesArr || (SELECT ARRAY_AGG(V.Id) FROM Vehicle AS V WHERE v.IdFleet IN (SELECT * FROM UNNEST(vGroups))); 
					vResult.code := 200; vResult.status := TRUE; vResult.message := 'No Vehicles';
					vResult.data := '[]'::JSON;
					RETURN TO_JSON(vResult);
				ELSE --EN CASO CONTRARIO, LLENAR EL ARREGLO NATIVO
					vVehiclesArr := (SELECT ARRAY_AGG(DISTINCT REPLACE(dt::TEXT, '"', '')) FROM JSON_ARRAY_ELEMENTS(vVehicles) AS dt);
					IF (JSON_ARRAY_LENGTH(COALESCE(vRules, '[]'::JSON)) <= 0) THEN 
						vRulesArr := (SELECT ARRAY_AGG(DISTINCT gr.id_geotabruleserial)
										FROM geotabrule AS gr
										INNER JOIN geotabRuleByVehicle AS grbv
										ON gr.id_geotabruleserial = grbv.id_geotabruleserial AND 
										grbv.id_vehicle IN (SELECT * FROM UNNEST(vVehiclesArr)));
					END IF;
				END IF;
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
				/*CONSULTAS DINÁMICAS*/
				vCurrentDate := (TO_CHAR(vStartTime, 'YYYY-MM') || '-01 00:00:00')::TIMESTAMP(0);
				WHILE (vCurrentDate <= vEndTime) LOOP
						IF EXISTS (SELECT FROM information_schema.tables WHERE  table_schema = 'public' AND table_name = 'geotabalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM')) THEN
							vQueries[vCount] := 'SELECT dt.*, geotab_last_alert_attend_detail_fn(dt."idNotify", ' || QUOTE_LITERAL(vOffsetInt) || ', ' || vUserLng ||') AS "details",
												geotab_historical_attend_alarms_fn(dt."idNotify", ' || QUOTE_LITERAL(vOffsetInt) || ' ) AS "historicalAttends",
												geotab_historical_classification_alarms_fn(dt."idNotify", '|| QUOTE_LITERAL(vOffsetInt) ||' ) AS "historicalClassification", '
												|| QUOTE_LITERAL('geotab') || ' AS "source", COALESCE(get_geotab_evidence_count(dt."idNotify"),0) as "evidenceCount",
												COALESCE((CASE WHEN eet.message IS NULL THEN ee.message ELSE eet.message END), ' || QUOTE_LITERAL('') || ' ) AS "errorMessage",
												CASE WHEN ee.state = ' || QUOTE_LITERAL(6) || ' AND ee.substate = ' || QUOTE_LITERAL(3) || ' THEN TRUE ELSE FALSE END AS "isOnGeofence"
												FROM
												(
													SELECT ga.Id_geotabalarm AS "idNotify",
													v.Id AS "idVehicle",
													vd.serial AS "serialMDVR",
													v.VIN,
													v.name AS "eco", ga.gpslat AS "latitude", ga.gpslng AS "longitude", ga.gpsTime::TIMESTAMP(0) + ' || QUOTE_LITERAL(vOffsetInt)  || ' AS "dateTime",
													ga.gpsTime::TIMESTAMP(0) AS "utcTime",
													CASE WHEN (SELECT MIN(date_attended) FROM attendgeotabalarm WHERE id_geotabalarm = ga.id_geotabalarm) IS NULL THEN FALSE ELSE TRUE END AS attended,
													(select id_user from attendGeotabAlarm where id_geotabAlarm = ga.id_geotabalarm FETCH FIRST 1 ROWS ONLY) as "IdUser",
													gr.name AS "ruleName", gr.is_popup AS "isPopup", gr.is_email AS "isEmail", 
													gr.id_geotabruleserial AS "idRule", gr.video_required AS "videoRequired", ac.alarm_category_id AS "alarmCategoryId", 
													CASE WHEN act.name IS NULL THEN ac.name ELSE act.name END AS category, ac.value AS "alarmColor",
													CASE WHEN EXISTS(SELECT * FROM task_video_data WHERE Id_geotabalarm = ga.Id_geotabalarm) THEN TRUE ELSE FALSE END AS "hasData",
													CASE WHEN (SELECT MIN(date_attended) FROM attendgeotabalarm WHERE id_geotabalarm = ga.id_geotabalarm) IS NULL THEN FALSE ELSE TRUE END AS "isPopupAt",
													(SELECT MIN(date_attended) + ' || QUOTE_LITERAL(vOffsetInt) || ' FROM attendgeotabalarm WHERE id_geotabalarm = ga.id_geotabalarm) AS "attendedTime",
													CASE WHEN (SELECT MIN(date_sent_email) FROM attendgeotabalarm WHERE id_geotabalarm = ga.id_geotabalarm) IS NULL THEN FALSE ELSE TRUE END AS "isEmailAt",
													geotab_alarm_attender_fn(ga.id_geotabalarm, ' || QUOTE_LITERAL(vOffsetInt) || ' ) AS "attendedBy",
													COALESCE(ga.geotab_driver_name, '|| QUOTE_LITERAL('') ||') AS "driverName"
													FROM geotabalarm_' || TO_CHAR(vCurrentDate, 'YYYY_MM') || ' AS ga
													INNER JOIN geotabrule AS gr
													ON ga.id_geotabruleserial = gr.id_geotabruleserial
													INNER JOIN vehicle AS v
													ON ga.id_vehicle = v.Id
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
													AND act.language_id = ' || vUserLng || ' 
													WHERE gr.id_geotabruleserial IN (SELECT * FROM UNNEST( ' || QUOTE_LITERAL('{'||(SELECT ARRAY_TO_STRING(vRulesArr, ',', NULL))||'}') || '::BIGINT[] ))
													AND v.Id IN (SELECT * FROM UNNEST( ' || QUOTE_LITERAL('{' || (SELECT ARRAY_TO_STRING(vVehiclesArr, ',', NULL)) || '}') ||'::BIGINT[] ))
													AND ga.gpsTime BETWEEN ' || QUOTE_LITERAL(vStartTime) || ' AND ' || QUOTE_LITERAL(vEndTime) || ' 
													GROUP BY ga.id_geotabalarm, v.id, v.serialmdvr, v.vin, ga.gpslat, ga.gpslng, ga.gpstime, gr.name, 
													gr.is_popup, gr.is_email, gr.id_geotabruleserial, gr.video_required, ac.alarm_category_id,
													act.name, ac.name, ac.value, v.name, ga.geotab_driver_name
												) AS dt
												LEFT JOIN geotab_download_task AS gdt
												ON dt."idNotify" = gdt.id_geotabalarm
												LEFT JOIN evidence_error AS ee
												ON gdt.state = ee.state AND gdt.substate = ee.substate
												LEFT JOIN evidence_error_trans AS eet
												ON eet.evidence_error_id = ee.evidence_error_id AND eet.language_id = ' || vUserLng;
							vCount := vCount + 1;
						END IF;
						vCurrentDate := vCurrentDate + INTERVAL '1 MONTH';
						--RAISE NOTICE '%', vQueries[vCount - 1];
					END LOOP;
				vQuery := ARRAY_TO_STRING(vQueries, ' UNION ALL ');
				RAISE NOTICE '%', vQuery;
				IF (LENGTH(COALESCE(vQuery, '')) < 50) THEN
					RAISE EXCEPTION 'No se encontró información en el periodo de búsqueda (Desde: %, Hasta: %)', vStartTime, vEndTime;
				END IF;
				/* TESTING */
				RAISE NOTICE 'Datos a Enviar: -----';
				RAISE NOTICE 'Offset: %', vOffsetInt;
				RAISE NOTICE 'Rules: %', vRulesArr;
				RAISE NOTICE 'Vehicles: %', vVehiclesArr;
				RAISE NOTICE 'From Date: %	| To Date: %', vStartTime, vEndTime;
				--REGRESAR RESULTADOS:
				vResult.code := 200; vResult.status := TRUE; vResult.message := '';
				EXECUTE 'SELECT COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
										FROM
										( 
											SELECT dt.*, JSON_BUILD_ARRAY(groups.group) AS "groups" 
											FROM
											('
											|| 
												vQuery 
											|| ') AS dt
											INNER JOIN 
											(
												SELECT f.name AS "group", ARRAY_AGG(v.id) AS vehicles
												FROM vehicle AS v
												INNER JOIN fleet AS f
												ON v.idfleet = f.id
												GROUP BY f.name
											) AS "groups"
											ON dt."idVehicle" = ANY(groups.vehicles)
											ORDER BY 8 DESC
										) AS dt), ' || QUOTE_LITERAL('[]') || '::JSON )' INTO vResult.data;
				RETURN TO_JSON(vResult);
			END
$BODY$;

ALTER FUNCTION public.geotab_alarm_by_user_select_fn(character varying, timestamp without time zone, timestamp without time zone, json, json, integer)
    OWNER TO mmcam_dev;
