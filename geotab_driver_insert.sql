-- FUNCTION: public.geotab_driver_insert(character varying, character varying, character varying, character varying, character varying, character varying, json, character varying, character varying, character varying)

-- DROP FUNCTION IF EXISTS public.geotab_driver_insert(character varying, character varying, character varying, character varying, character varying, character varying, json, character varying, character varying, character varying);

CREATE OR REPLACE FUNCTION public.geotab_driver_insert(
	vtoken character varying,
	vdriverid character varying,
	vfirstname character varying,
	vlastname character varying,
	vemail character varying,
	vphonenumber character varying,
	vgroups json,
	vdriverkey character varying,
	vserial character varying,
	vcomments character varying DEFAULT ''::character varying)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
  declare
    vUserId		BIGINT;
    vUsername varchar;
    vResult 	tpResponse;
	vUserLng	INT DEFAULT 2;
  begin
    vUserId := checkValidToken(vToken);
    vUsername := (SELECT username FROM "user" WHERE id = vUserId);
    vUserLng := (SELECT language_id FROM userconfig WHERE IdUser = vUserId LIMIT 1);
    IF (vFirstName IS NULL OR vLastName IS NULL) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 1, '{}'::VARCHAR[]);
        END IF;
        IF ( LENGTH(vFirstName) IS NULL OR LENGTH(vLastName) <= 0) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 2, '{}'::VARCHAR[]);
        END IF;
        --VERIFICAR QUE GRUPOS NO ESTÉ VACÍO
        IF (JSON_ARRAY_LENGTH(vGroups)<= 0) THEN
          --RAISE EXCEPTION 'Debe de asignar por lo menos un grupo al conductor'; --11 1 4
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 3, '{}'::VARCHAR[]);
        END IF;

        IF (vDriverId IS NULL) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 4, '{}'::VARCHAR[]);
        END IF;

        IF (LENGTH(vDriverId) <= 0) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 5, '{}'::VARCHAR[]);
        END IF;

        IF (vEmail IS NULL) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 6, '{}'::VARCHAR[]);
        END IF;

        IF (LENGTH(vEmail) <= 0) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 7, '{}'::VARCHAR[]);
        END IF;

        IF (vPhoneNumber IS NULL) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 8, '{}'::VARCHAR[]);
        END IF;

        IF (LENGTH(vPhoneNumber) <= 0) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 9, '{}'::VARCHAR[]);
        END IF;

        IF (vDriverKey IS NULL) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 10, '{}'::VARCHAR[]);
        END IF;

        IF (LENGTH(vDriverKey) <= 0) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 11, '{}'::VARCHAR[]);
        END IF;

        IF (vSerial IS NULL) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 12, '{}'::VARCHAR[]);
        END IF;

        IF (LENGTH(vSerial) <= 0) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 13, '{}'::VARCHAR[]);
        END IF;

        IF EXISTS (SELECT driver_id from geotab_driver where driver_id like vDriverId) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 14, '{}'::VARCHAR[]);
        END IF;

        IF EXISTS (SELECT email from geotab_driver where email like vEmail) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 15, '{}'::VARCHAR[]);
        END IF;
		
        IF NOT EXISTS (SELECT serialmdvr from vehicle where serialmdvr like vSerial) THEN
          RAISE EXCEPTION '%', message_select_fn(14, 1, vUserLng, 16, '{}'::VARCHAR[]);
        END IF;

        INSERT INTO geotab_driver(driver_id, first_name, last_name, email, phone_number, groups, driver_key, serial_mdvr, comments) values (vDriverId, vFirstName, vLastName, vEmail, vPhoneNumber, vGroups, vDriverKey, vSerial, vComments)
        ON CONFLICT ON CONSTRAINT driver_id_un
        DO NOTHING;

    PERFORM auditlog_insert_fn(vUsername, 'Conductores de Geotab.', 'Conductor creado',
              CONCAT('Se creó el conductor ', vFirstName ,' ',vLastName));

              --INICIALIZAR RESPUESTA
              vResult.code := 200; vResult.status := TRUE; vResult.message := message_select_fn(11, 2, vUserLng, 7, '{}'::VARCHAR[]);
              --OBTENER DATOS
              vResult.data := COALESCE((SELECT ROW_TO_JSON(dt) FROM
                          (
                            SELECT d.geotab_driver_id AS "geotabDriverId", 
                            d.first_name as name, d.last_name AS "lastName",
                            COALESCE(d.phone_number, '') AS phone, d.email,
                            d.serial_mdvr,d.groups
                            FROM geotab_driver AS d
                            WHERE d.driver_id = vDriverId
                          ) AS dt), '{}'::JSON);
              RETURN TO_JSON(vResult);
  end;
  
$BODY$;

ALTER FUNCTION public.geotab_driver_insert(character varying, character varying, character varying, character varying, character varying, character varying, json, character varying, character varying, character varying)
    OWNER TO mmcam_dev;
