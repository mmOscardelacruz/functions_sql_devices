-- FUNCTION: public.geotab_rules_select_fn(character varying)

-- DROP FUNCTION IF EXISTS public.geotab_rules_select_fn(character varying);

CREATE OR REPLACE FUNCTION public.geotab_rules_select_fn(
	vtoken character varying)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vIdUser	BIGINT;
	vIdFleets BIGINT[];
	vUserLng	INT;
	vResult tpResponse;
BEGIN
	/*IF NOT EXISTS(SELECT * FROM SessionManagement WHERE SessionT LIKE vToken) THEN
		RAISE EXCEPTION 'La sesión actual no está asignada para un usuario';
	END IF;
	IF NOT(SELECT IsActive FROM SessionManagement WHERE SessionT LIKE vToken AND NOW() < ExpirationD ORDER BY DateTime DESC LIMIT 1) THEN
		RAISE EXCEPTION 'Verifique que cuente con una sesión activa o que no haya expirado';
	END IF;*/--SE QUITAN PORQUE PARA ESO SE USA EL VERIFICAR EL TOKEN VÁLIDO
	vIdUser := checkValidToken(vToken);
	vIdFleets := getPlainGroupsAll(vIdUser);
	--OBTENER TODAS LAS REGLAS QUE AFECTAN A LOS GRUPOS DEL USUARIO
	vIdFleets := group_branches_upper_and_lower(vIdFleets);
	vUserLng := (SELECT language_id FROM userconfig WHERE IdUser = vIdUser);
	--INICIALIZAR RESULTADOS:
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	vResult.data := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
							 FROM
							 (
								 SELECT gr.id_geotabruleserial AS "idGeotabRuleSerial", gr.id_geotabrule AS "idGeotabRule", gr.name, 
								 gr.description, gr.secs_preevent AS "secsPreEvent", gr.secs_posevent AS "secsPosEvent",
								 gr.creation_date AS "creationDate", gr.is_public AS "isPublic", gr.is_popup AS "isPopup", gr.is_email AS "isEmail",
								 gr.is_active AS "isActive",
								 (CASE WHEN gr.id_user = vIdUser OR gr.is_public THEN TRUE ELSE FALSE END) AS "isCreator",
								 gr.gif_required AS "gifRequired", gr.video_required AS "videoRequired",
								 u.id AS "idUser", u.username,
								 ac.alarm_category_id AS "alarmCategoryId", 
								 CASE WHEN act.name IS NULL THEN ac.name ELSE act.name END AS "cateogryAlarm",
								 geotab_rule_vehicles_fn(gr.id_geotabruleserial) AS "vehicles",
								 geotab_rule_groups_fn(gr.id_geotabruleserial) AS "groups",
								 geotab_rule_email_fn(gr.id_geotabruleserial) AS "emails",
								 gr.zone_restriction_id_entry AS "zoneRestrictionIdEntry",
								 gr.zone_restriction_name_entry AS "zoneRestrictionNameEntry",
								 gr.zone_restriction_id_exit AS "zoneRestrictionIdExit",
								 gr.zone_restriction_name_exit AS "zoneRestrictionNameExit",
								 gr.zone_restriction AS "zoneRestriction"
								 FROM geotabrule AS gr
								 INNER JOIN "user" AS u
								 ON gr.id_user = u.Id
								 LEFT JOIN geotabrulebyvehicle AS grbv
								 ON gr.id_geotabruleserial = grbv.id_geotabruleserial
								 LEFT JOIN geotabrulebygroup AS grbg
								 ON gr.id_geotabruleserial = grbg.id_geotabruleserial
								 LEFT JOIN rule_geotab_category AS rgc
								 ON gr.id_geotabruleserial = rgc.geotab_rule_id
								 LEFT JOIN alarm_category AS ac
								 ON rgc.alarm_category_id = AC.alarm_category_id
								 LEFT JOIN alarm_category_trans AS act
								 ON ac.alarm_category_id = act.alarm_category_id 
								 AND act.language_id = vUserLng
								 WHERE grbg.id_fleet IN (SELECT * FROM UNNEST(vIdFleets))
								 OR gr.id_user = vIdUser
								 OR grbv.id_vehicle IN (SELECT Id FROM Vehicle WHERE IdFleet IN (SELECT * FROM UNNEST(vIdFleets)))
								 GROUP BY gr.id_geotabruleserial, gr.id_geotabrule, gr.Name, gr.Description, gr.is_public, gr.is_PopUp, gr.is_email, 
								 gr.secs_preevent, gr.secs_posevent, gr.is_active, gr.creation_date, 
								 gr.id_user, ac.alarm_category_id, act.name, ac.name, ac.value, u.id, u.username
								 ORDER BY gr.Name ASC
							 ) AS dt), '[]'::JSON);
	RETURN TO_JSON(vResult);	
END
$BODY$;

ALTER FUNCTION public.geotab_rules_select_fn(character varying)
    OWNER TO mmcam_dev;
