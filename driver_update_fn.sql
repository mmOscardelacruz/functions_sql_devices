-- FUNCTION: public.driver_update_fn(character varying, integer, character varying, character varying, json, json, character varying, character varying, character varying, date, character varying, character varying, character varying, json)

-- DROP FUNCTION IF EXISTS public.driver_update_fn(character varying, integer, character varying, character varying, json, json, character varying, character varying, character varying, date, character varying, character varying, character varying, json);

CREATE OR REPLACE FUNCTION public.driver_update_fn(
	vtoken character varying,
	vdriverid integer,
	vname character varying,
	vlastname character varying,
	vgroups json,
	vvehicles json,
	vnss character varying,
	vgeotabid character varying DEFAULT ''::character varying,
	vemployeeno character varying DEFAULT ''::character varying,
	vbirthday date DEFAULT '2022-02-25'::date,
	vphone character varying DEFAULT ''::character varying,
	vlicense character varying DEFAULT ''::character varying,
	vemail character varying DEFAULT ''::character varying,
	vfaces json DEFAULT '[]'::json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
						vUserId		BIGINT;
						vUsername varchar;
						vResult 	tpResponse;
						/*LANGUAGE*/
						vUserLng	INT;
					BEGIN
						--VERIFICAR QUE EL TOKEN SEA VÁLIDO
						vUserId := checkValidToken(vToken);
						vUsername := (SELECT username FROM "user" WHERE id = vUserId);
						--OBTENER EL IDIOMA DEL USUARIO
						vUserLng := (SELECT language_id FROM userconfig WHERE IdUser = vUserId);
						-- Verificar el NSS
						-- IF(LENGTH(vNss) > 0) THEN
							IF EXISTS (SELECT * FROM farec.driver WHERE nss LIKE vNss and driver_id <> vdriverid) THEN
								RAISE EXCEPTION '%', message_select_fn(11, 2, vUserLng, 8, '{}'::VARCHAR[]);
							END IF;
							-- RAISE EXCEPTION 'El NSS no debe estar vacio';
						-- END IF;
						--VERIFICAR QUE NO EXISTA EL NÚMERO DEL EMPLEADO SI ES QUE NO VIENE VACÍO
						IF(LENGTH(vEmployeeNo) > 0) THEN
							IF EXISTS (SELECT * FROM farec.driver WHERE employee_number LIKE vEmployeeNo AND driver_id <> vDriverId) THEN
								RAISE EXCEPTION '%', message_select_fn(11, 2, vUserLng, 1, '{}'::VARCHAR[]);
							END IF;
						END IF;
						--VERIFICAR QUE EL NOMBRE Y APELLIDO NO VENGAN VACÍOS O NULOS
						IF (vName IS NULL OR vLastName IS NULL) THEN
							RAISE EXCEPTION '%', message_select_fn(11, 2, vUserLng, 2, '{}'::VARCHAR[]);
						END IF;
						IF (LENGTH(vName) <= 0 OR LENGTH(vLastName) <= 0) THEN
							RAISE EXCEPTION '%', message_select_fn(11, 2, vUserLng, 3, '{}'::VARCHAR[]);
						END IF;
						/*--VERIFICAR QUE NO EXISTA EL NOMBRE Y APELLIDO
						IF EXISTS (SELECT * FROM farec.driver WHERE UPPER(name) LIKE UPPER(vName) AND UPPER(last_name) LIKE UPPER(vLastName) AND driver_id <> vDriverId) THEN
							RAISE EXCEPTION '%', message_select_fn(11, 2, vUserLng, 4, '{}'::VARCHAR[]);
						END IF;*/
						--VERIFICAR QUE GRUPOS NO ESTÉ VACÍO
						IF (JSON_ARRAY_LENGTH(vGroups)<= 0) THEN
							RAISE EXCEPTION '%', message_select_fn(11, 2, vUserLng, 5, '{}'::VARCHAR[]);
						END IF;
						--VERIFICAR QUE VEHÍCULOS NO ESTÉ VACIÓ
						IF (vVehicles IS NULL) THEN
							RAISE EXCEPTION '%', message_select_fn(11, 2, vUserLng, 6, '{}'::VARCHAR[]);
						END IF;
						--ACTUALIZAR DATOS DE CONDUCTOR
						--SELECT * FROM farec.driver
						UPDATE farec.driver SET (geotab_id, name, last_name, employee_number, phone, license, email, birthday, nss)
						= (vGeotabId, vName, vLastName, vEmployeeNo, vPhone, vLicense, vEmail, vBirthday, vNSS) WHERE driver_id = vDriverId;
						--INSERTAR DATOS DE GRUPO DE CONDUCTORES
						DELETE FROM farec.driver_group WHERE driver_id = vDriverId;
						INSERT INTO farec.driver_group (driver_id, group_id)
						SELECT vDriverId, dt::TEXT::INT
						FROM JSON_ARRAY_ELEMENTS(vGroups) AS dt;
						--INSERTAR DATOS DE VEHÍCULOS
						DELETE FROM farec.driver_vehicle WHERE driver_id = vDriverId;
						INSERT INTO farec.driver_vehicle (driver_id, vehicle_id) 
						--VALUES(vDriverId, vVehicles);
						SELECT vDriverId, REPLACE(dt::VARCHAR, '"', '')::INT
						FROM JSON_ARRAY_ELEMENTS(vVehicles) AS dt;
						--INSERTAR DATOS DE CAPTURAS SI ES QUE LLEGARON
						DELETE FROM farec.face WHERE driver_id = vDriverId;
						IF (JSON_ARRAY_LENGTH(vFaces) > 0) THEN
						if exists (select face_id from farec.face where face_id in (SELECT dt->>'faceId'
					FROM JSON_ARRAY_ELEMENTS(vFaces) as dt)) then
					RAISE EXCEPTION 'Imagen ya asignada a otro conductor.';
				END IF;
							INSERT INTO farec.face (driver_id, face_id, autorized, path)
							SELECT vDriverId, REPLACE((dt->'faceId')::TEXT, '"', ''), 
							TRUE, REPLACE((dt->'faceUrl')::TEXT, '"', '')
							FROM JSON_ARRAY_ELEMENTS(vFaces) AS dt;
						END IF;
						--REGRESAR DATOS CORRECTOS
						PERFORM auditlog_insert_fn(vUsername, 'Conductores.', 'Conductor editado',
						CONCAT('Se editó el conductor ', vName ,' ',vLastName));
						--INICIALIZAR RESPUESTA
						vResult.code := 200; vResult.status := TRUE; vResult.message := message_select_fn(11, 2, vUserLng, 7, '{}'::VARCHAR[]);
						--OBTENER DATOS
						vResult.data := COALESCE((SELECT ROW_TO_JSON(dt) FROM
												(
													SELECT d.driver_id AS "driverId", d.geotab_id AS "geotabId",
													d.name, d.last_name AS "lastName", COALESCE(d.employee_number, '') AS "employeeNumber",
													COALESCE(d.phone, '') AS phone, COALESCE(d.license, '') AS license, COALESCE(d.email,'') AS email, d.birthday, 
													COALESCE(d.nss, '') AS nss,
													driver_group_select_fn(d.driver_id) AS "groups",
													driver_face_select_fn(d.driver_id) AS "faces",
													driver_vehicle_select_fn(d.driver_id) AS "vehicles"
													FROM farec.driver AS d
													WHERE d.driver_id = vDriverId
												) AS dt), '{}'::JSON);
						RETURN TO_JSON(vResult);
					END
$BODY$;

ALTER FUNCTION public.driver_update_fn(character varying, integer, character varying, character varying, json, json, character varying, character varying, character varying, date, character varying, character varying, character varying, json)
    OWNER TO mmcam_dev;
