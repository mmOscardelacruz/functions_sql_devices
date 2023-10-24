-- FUNCTION: public.driver_select_fn(character varying, json, json)

-- DROP FUNCTION IF EXISTS public.driver_select_fn(character varying, json, json);

CREATE OR REPLACE FUNCTION public.driver_select_fn(
	vtoken character varying,
	vgroups json DEFAULT '[]'::json,
	vvehicles json DEFAULT '[]'::json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vUserId			BIGINT;
	vResult 		tpResponse;
	vDrivers		INT[];
	vUserGroups		BIGINT[];
	vVehiclesArr	BIGINT[];
	vGroupsArr		BIGINT[];
BEGIN
	--VERIFICAR QUE EL TOKEN SEA VÁLIDO
	vUserId := checkValidToken(vToken);
	vUserGroups := getPlainGroupsAll(vUserId);
	--VERIFICAR QUE VENGAN DATOS DE GRUPOS
	IF (vGroups IS NULL) THEN
		vGroupsArr := vUserGroups;
	--ELSE
		--vGroupsArr := (SELECT ARRAY_AGG(dt::TEXT::BIGINT) FROM JSON_ARRAY_ELEMENTS(vGroups) AS dt);
	END IF;
	IF (JSON_ARRAY_LENGTH(vGroups) <= 0) THEN
		vGroupsArr := vUserGroups;
	ELSE
		vGroupsArr := (SELECT ARRAY_AGG(dt::TEXT::BIGINT) FROM JSON_ARRAY_ELEMENTS(vGroups) AS dt);
	END IF;
	--VERIFICAR QUE VENGAN DATOS DE VEHÍCULOS
	IF (vVehicles IS NULL) THEN
		vVehiclesArr := (SELECT ARRAY_AGG(DISTINCT Id) FROM vehicle WHERE IdFleet IN (SELECT * FROM UNNEST(vGroupsArr)));
	--ELSE
		--vVehiclesArr := (SELECT ARRAY_AGG(dt::TEXT::BIGINT) FROM JSON_ARRAY_ELEMENTS(vVehicles) AS dt);
	END IF;
	IF (JSON_ARRAY_LENGTH(vVehicles) <= 0) THEN
		vVehiclesArr := (SELECT ARRAY_AGG(DISTINCT Id) FROM vehicle WHERE IdFleet IN (SELECT * FROM UNNEST(vGroupsArr)));
	ELSE
		vVehiclesArr := (SELECT ARRAY_AGG(dt::TEXT::BIGINT) FROM JSON_ARRAY_ELEMENTS(vVehicles) AS dt);
	END IF;
	--OBTENER CONDUCTORES
	vDrivers := (SELECT ARRAY_AGG(DISTINCT driver_id)
				 FROM
				 (
					 SELECT dv.driver_id
					 FROM farec.driver_vehicle AS dv
					 WHERE dv.vehicle_id IN (SELECT * FROM UNNEST(vVehiclesArr))
					 UNION ALL
					 SELECT dg.driver_id
					 FROM farec.driver_group AS dg
					 WHERE dg.group_id IN (SELECT * FROM UNNEST(vGroupsArr) AS dt)
				 ) AS dt);
	/*RAISE NOTICE 'USER GROUPS: %', vUserGroups;
	RAISE NOTICE 'GROUPS: %', vGroupsArr;
	RAISE NOTICE 'VEHICLES: %', vVehiclesArr;
	RAISE NOTICE 'DRIVERS: %', vDrivers;*/
	--INICIALIZAR RESPUESTA
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	--OBTENER DATOS
	vResult.data := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt)) FROM
							 (
								SELECT d.driver_id AS "driverId", d.geotab_id AS "geotabId",
								 d.name, d.last_name AS "lastName", d.employee_number AS "employeeNumber",
								 d.NSS AS "NSS", d.birthday, d.ftapi_driver_id AS "ftaDriverId",
								 d.phone, d.license, d.email,
								 drr.rule_id, drr.rule_name,
								 driver_group_select_fn(d.driver_id) AS "groups",
								 driver_face_select_fn(d.driver_id) AS "faces",
								 driver_vehicle_select_fn(d.driver_id) AS "vehicles",
								 COALESCE(pp.picture_name, '') AS "profilePicture"
								 FROM farec.driver AS d
								 LEFT JOIN farec.profile_picture AS pp
								 ON d.driver_id = pp.driver_id AND pp.active
								 LEFT JOIN farec.driver_rule AS drr
								 ON d.driver_id = drr.driver_id
								 WHERE d.driver_id IN (SELECT * FROM UNNEST(vDrivers))
							 ) AS dt), '[]'::JSON);
	RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.driver_select_fn(character varying, json, json)
    OWNER TO mmcam_dev;
