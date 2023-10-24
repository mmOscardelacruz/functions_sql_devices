-- FUNCTION: public.createGeotabRule(character varying, character varying, character varying, integer, integer, timestamp without time zone, boolean, boolean, boolean, text[], boolean, boolean, boolean, character varying, json, json, integer, json, character varying, character varying, character varying, character varying, boolean)

-- DROP FUNCTION IF EXISTS public."createGeotabRule"(character varying, character varying, character varying, integer, integer, timestamp without time zone, boolean, boolean, boolean, text[], boolean, boolean, boolean, character varying, json, json, integer, json, character varying, character varying, character varying, character varying, boolean);

CREATE OR REPLACE FUNCTION public."createGeotabRule"(
	vidgeotabrule character varying,
	vname character varying,
	vdescription character varying,
	vsecspreevent integer,
	vsecsposevent integer,
	vcreationdate timestamp without time zone,
	vispublic boolean,
	vispopup boolean,
	visemail boolean,
	vemaillist text[],
	visactive boolean,
	vgifrequired boolean,
	vvideorequired boolean,
	vtoken character varying,
	vidfleet json,
	vidvehicle json,
	valarmcategoryid integer DEFAULT 2,
	vcams json DEFAULT NULL::json,
	vzonerestrictionidentry character varying DEFAULT ''::character varying,
	vzonerestrictionnameentry character varying DEFAULT ''::character varying,
	vzonerestrictionidexit character varying DEFAULT ''::character varying,
	vzonerestrictionnameexit character varying DEFAULT ''::character varying,
	viszonerestriction boolean DEFAULT false)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
  DECLARE
    vResult tpResponse;
    vIdUser		BIGINT;
    vIdUsers 	BIGINT[];
    vData		RECORD;
    vUsername	TEXT;
    vUserLng	INT;
    vIdRule INT;
    BEGIN
    
      /*CHECAR PARÁMETROS: TEMP
      INSERT INTO check_data (function_name, data, date_time)
      VALUES ('createGeotabRule', JSON_BUILD_OBJECT('IdGeotabRule', vIdGeotabRule, 'name', vName, 'description', vDescription, 'secsPreEvent', vSecsPreEvent,
                            'secsPosEvent', vSecsPosEvent, 'creationDate', vCreationDate, 'isPublic', vIsPublic, 'isPopup', vIsPopup,
                            'isEmail', vIsEmail, 'emailList', vEmailList, 'isActive', vIsActive, 'gifRequired', vGifRequired,
                            'videoRequired', vVideoRequired, 'token', vToken, 'idFleet', vIdFleet, 'idVehicle', vIdVehicle,
                            'alarmCateogryId', vAlarmCategoryId, 'cams', vCams), NOW());
      FIN DE CHECAR PARÁMETROS*/
      vIdUser := checkValidToken(vToken);
      --vIdUser := vToken::int; --fines de testeo
      vUsername := (SELECT username FROM "user" WHERE id = vIdUser);
      --OBTENER EL IDIOMA DEL USUARIO
      vUserLng := (SELECT language_id FROM userconfig WHERE IdUser = vIdUser);
      IF (vIdFleet IS NOT NULL) THEN
        IF EXISTS (SELECT * FROM GeotabRule AS R INNER JOIN GeotabRulebyGroup AS RBG ON R.id_GeotabRuleSerial = RBG.id_GeotabRuleSerial 
              WHERE RBG.Id_Fleet IN (SELECT CAST(dt->>'id' AS BIGINT) FROM JSON_ARRAY_ELEMENTS(vIdFleet) AS dt) AND EXISTS (SELECT * FROM GeotabRule where id_GeotabRule = vIdGeotabRule)) THEN
          RAISE EXCEPTION '%', message_select_fn(12, 1, vUserLng, 1, '{}'::VARCHAR[]);--Insertar nuevos registros para reglas
        END IF;
      END IF;
      --SI VA A SER UNA ALARMA POR VEHÍCULOS, CHECAR QUE NO EXISTA YA:
      IF (vIdVehicle IS NOT NULL) THEN
        IF EXISTS (SELECT * FROM GeotabRule AS R INNER JOIN GeotabRulebyVehicle AS RBV ON R.id_GeotabRuleSerial = RBV.id_GeotabRuleSerial WHERE RBV.id_Vehicle IN (SELECT CAST(dt->>'id' AS BIGINT) FROM JSON_ARRAY_ELEMENTS(vIdVehicle) AS dt) AND EXISTS (SELECT * FROM GeotabRule where id_GeotabRule = vIdGeotabRule)) THEN
          RAISE EXCEPTION '%', message_select_fn(12, 1, vUserLng, 2, '{}'::VARCHAR[]);--Insertar nuevos registros para reglas
        END IF;
      END IF;
      --VERIFICAR SI HAY DATOS EN GRUPOS O VEHÍCULOS
      IF (vIdFleet IS NULL AND vIdVehicle IS NULL) THEN
        RAISE EXCEPTION '%', message_select_fn(12, 1, vUserLng, 3, '{}'::VARCHAR[]);
      END IF;
      IF (JSON_ARRAY_LENGTH(vIdFleet) <= 0 AND JSON_ARRAY_LENGTH(vIdVehicle) <= 0) THEN
        RAISE EXCEPTION '%', message_select_fn(12, 1, vUserLng, 3, '{}'::VARCHAR[]);
      END IF;
      --SI NO EXISTE PARA EL MISMO GRUPO O LOS MISMOS VEHÍCULOS...
      --SI PASA LOS FILTROS DE EXCEPCIONES, ENTONCES, AGREGAR NUEVA REGLA.
      --VERIFICAR QUE EL NOMBRE DE LA REGLA QUE SE VA A INGRESAR, NO EXISTA PARA EL USUARIO
      IF EXISTS (SELECT * FROM GeotabRule WHERE UPPER(Name) LIKE UPPER(vName) AND Id_User = vIdUser) THEN
        RAISE EXCEPTION '%', message_select_fn(12, 1, vUserLng, 4, '{}'::VARCHAR[]);
      END IF;
      
      --VERIFICAR QUE NO HAYA GRUPOS Y VEHÍCULOS AL MISMO TIEMPO
      /*IF (vIdFleet IS NOT NULL AND vIdVehicle IS NOT NULL) THEN
        RAISE EXCEPTION 'Sólo puede enviar un arreglo de grupos o vehículos pero no ambos';
      END IF;*/
      IF (JSON_ARRAY_LENGTH(vIdFleet) > 0 AND JSON_ARRAY_LENGTH(vIdVehicle) > 0) THEN
        RAISE EXCEPTION 'Sólo puede enviar un arreglo de grupos o vehículos pero no ambos';
      END IF;
      
      IF(vCreationDate IS NULL) THEN vCreationDate := NOW(); END IF;
      
      /*IF(vZoneRestriction and vZoneRestrictionIds is null) then
            --RAISE EXCEPTION '%', message_select_fn(4, 1, vUserLng, 6, '{}'::VARCHAR[]);
      END IF;*/
    
      INSERT INTO GeotabRule
      (
        id_GeotabRule,
        name,
        Id_User,
        description,
        secs_preevent,
        Secs_posevent,
        creation_Date,
        is_public,
        is_popup,
        is_email,
        is_active,
        gif_required,
        video_required,
        zone_restriction_id_entry,
        zone_restriction_name_entry,
		zone_restriction_id_exit,
		zone_restriction_name_exit,
		zone_restriction
        )
      VALUES(
        vIdGeotabRule,
        vName,
        vIdUser,
        vDescription,
        vSecsPreEvent,
        vSecsPosEvent,
        vCreationDate,
        vIsPublic,
        vIsPopup,
        vIsEmail,
        vIsActive,
        vGifRequired,
        vVideoRequired,
        vZoneRestrictionIdEntry,
        vZoneRestrictionNameEntry,
		vZoneRestrictionIdExit,
		vZoneRestrictionNameExit,
		vIsZoneRestriction
        ) RETURNING id_GeotabRuleSerial into vIdRule;
      --SI NO ES NULO, INSERTAR EN REGLAS POR GRUPO
      
      IF(vIdFleet IS NOT NULL) THEN
        DELETE FROM GeotabRuleByGroup WHERE id_GeotabRuleSerial = vIdRule AND Id_Fleet IN (SELECT CAST(dt->>'id' AS INTEGER) FROM JSON_ARRAY_ELEMENTS(vIdFleet) AS dt);
        INSERT INTO GeotabRuleByGroup (id_GeotabRuleSerial, Id_Fleet, onOffCams)
        SELECT vIdRule, CAST(dt->>'id' AS INTEGER),CAST(dt->>'onOffCams' AS BOOLEAN) FROM JSON_ARRAY_ELEMENTS(vIdFleet) AS dt;
      END IF;
      --SI NO ES NULO, INSERTAR EN REGLAS POR VEHÍCULO
      IF (vIdVehicle IS NOT NULL) THEN
        DELETE FROM GeotabRuleByVehicle WHERE id_GeotabRuleSerial = vIdRule AND Id_Vehicle IN (SELECT CAST(dt->>'id' AS INTEGER) FROM JSON_ARRAY_ELEMENTS(vIdVehicle) AS dt);
        INSERT INTO GeotabRuleByVehicle (id_GeotabRuleSerial, Id_Vehicle, onOffCams)
        SELECT vIdRule, CAST(dt->>'id' AS INTEGER),CAST(dt->>'onOffCams' AS BOOLEAN) FROM JSON_ARRAY_ELEMENTS(vIdVehicle) AS dt;
      END IF;
          --INSERTAR EMAILS
      IF (vIsEmail) THEN
        IF (vEmailList IS NULL) THEN
          RAISE EXCEPTION '%', message_select_fn(12, 1, vUserLng, 5, '{}'::VARCHAR[]);
        END IF;
        IF (ARRAY_LENGTH(vEmailList, 1) <= 0) THEN
          RAISE EXCEPTION '%', message_select_fn(12, 1, vUserLng, 5, '{}'::VARCHAR[]);
        END IF;
        INSERT INTO Email (Email)
        SELECT dtEmail FROM UNNEST (vEmailList) AS dtEmail
        WHERE dtEmail NOT IN (SELECT Email FROM Email);
        INSERT INTO EmailByGeotabRule (id_GeotabRuleSerial, Id_mail)
        SELECT vIdRule, Id FROM Email
        WHERE Email IN (SELECT * FROM UNNEST(vEmailList));
      END IF;
      
      --AGREGAR LA CATEGORÍA A LA REGLA
      DELETE FROM rule_geotab_category WHERE geotab_rule_id = vIdRule;
      INSERT INTO rule_geotab_category (geotab_rule_id, alarm_category_id)
      VALUES (vIdRule, vAlarmCategoryId);

      --VERIFICAR QUE vCams no sea nulo
      DELETE FROM GeotabRuleCamera where id_geotabruleserial = vIdRule; --Puede ser innecesaria, ya que es el primer insert.
      IF (JSON_ARRAY_LENGTH(COALESCE(vCams, '[]'::JSON)) > 0) THEN
        INSERT INTO GeotabRuleCamera (id_geotabruleserial, camera_type_id, channel)
        SELECT vIdRule, CAST(dt->>'id' AS INTEGER),CAST(dt->>'channel' AS INTEGER) FROM JSON_ARRAY_ELEMENTS(vCams) AS dt;
      END IF;

      --AGREGAR AL AUDIT LOG
      PERFORM auditlog_insert_fn(vUsername, 'Reglas de MyGeotab', 'Alta de reglas', CONCAT('Creó la regla ', vName));
      
      vResult.code := 200; vResult.status := TRUE; vResult.message := '';
      vResult.data := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
                  FROM
                  (
                    SELECT gr.id_geotabruleserial AS "idGeotabRuleSerial", gr.id_geotabrule AS "idGeotabRule",
                    gr.name, gr.description, gr.secs_preevent AS "secsPreEvent", gr.secs_posevent AS "secsPosEvent",
                    gr.creation_date AS "creationDate", gr.is_public AS "isPublic", gr.is_popup AS "isPopup", gr.is_email AS "isEmail",
                    gr.is_active AS "isActive", gr.gif_required AS "gifRequired", gr.video_required AS "videoRequired",
                    u.id AS "idUser", u.username,
                    ac.alarm_category_id AS "alarmCategoryId", 
                    CASE WHEN act.name IS NULL THEN ac.name ELSE act.name END AS "cateogryAlarm",
                    geotab_rule_vehicles_fn(gr.id_geotabruleserial) AS "vehicles",
                    geotab_rule_groups_fn(gr.id_geotabruleserial) AS "groups",
                    geotab_rule_email_fn(gr.id_geotabruleserial) AS "emails",
					gr.zone_restriction_id_entry AS "zoneRestrictionIdEntry", gr.zone_restriction_name_entry AS "zoneRestrictionNameEntry",
					gr.zone_restriction_id_exit AS "zoneRestrictionIdExit", gr.zone_restriction_name_exit AS "zoneRestrictionNameExit",
					gr.zone_restriction AS "zoneRestriction"
                    FROM geotabRule AS gr
                    INNER JOIN "user" AS u
                    ON gr.id_user = u.id
                    INNER JOIN rule_geotab_category AS rgc
                    ON gr.id_geotabruleserial = rgc.geotab_rule_id
                    INNER JOIN alarm_category AS ac
                    ON rgc.alarm_category_id = ac.alarm_category_id
                    LEFT JOIN alarm_category_trans AS act
                    ON ac.alarm_category_id = act.alarm_category_id AND act.language_id = vUserLng
                    WHERE gr.id_geotabruleserial = vIdRule
                  ) AS dt), '[]'::JSON);
      RETURN TO_JSON(vResult);
    END
$BODY$;

ALTER FUNCTION public."createGeotabRule"(character varying, character varying, character varying, integer, integer, timestamp without time zone, boolean, boolean, boolean, text[], boolean, boolean, boolean, character varying, json, json, integer, json, character varying, character varying, character varying, character varying, boolean)
    OWNER TO mmcam_dev;
