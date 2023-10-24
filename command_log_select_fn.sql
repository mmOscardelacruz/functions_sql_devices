-- FUNCTION: public.command_log_select_fn(character varying, timestamp without time zone, timestamp without time zone, json, json, json)

-- DROP FUNCTION IF EXISTS public.command_log_select_fn(character varying, timestamp without time zone, timestamp without time zone, json, json, json);

CREATE OR REPLACE FUNCTION public.command_log_select_fn(
	vsessiontoken character varying,
	vfromdate timestamp without time zone,
	vtodate timestamp without time zone,
	vcommandtypeid json DEFAULT '[]'::json,
	vusername json DEFAULT '[]'::json,
	vgeotabruleid json DEFAULT '[]'::json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vIdUser 		BIGINT;
	vLangId			INT;
	vResult			tpResponse;
	vCommandTypes	INT[];
	vUsernames		VARCHAR[];
	vGeotabRules	VARCHAR[];
BEGIN
	--VALIDAR EL TOKEN
	vIdUser := checkValidToken(vSessionToken);
	--OBTENER EL IDIOMA DEL USUARIO
	vLangId := (SELECT language_id FROM userconfig WHERE IdUser = vIdUser);
	IF (COALESCE(vFromDate, '2021-09-15 00:00:00') >= COALESCE(vToDate, '2021-09-15 00:00:00')) THEN
		RAISE EXCEPTION 'La fecha de inicio no puede ser menor a la fecha fin';
	END IF;
	--VERIFICAR QUE LOS IDs DE TIPO DE COMANDO ESTÉN LLENOS
	IF (JSON_ARRAY_LENGTH(COALESCE(vCommandTypeId, '[]')) <= 0) THEN
		vCommandTypes := (SELECT ARRAY_AGG(command_type_id) FROM command_type);
	ELSE
		vCommandTypes := (SELECT ARRAY_AGG(dt::TEXT::INT) FROM JSON_ARRAY_ELEMENTS(vCommandTypeId) AS dt);
	END IF;
	--VERIFICAR QUE LOS NOMBRES DE USUARIO ESTÉN LLENOS
	IF (JSON_ARRAY_LENGTH(COALESCE(vUsername, '[]')) <= 0) THEN
		vUsernames := (SELECT ARRAY_AGG(DISTINCT COALESCE(username, '')) FROM "user");
	ELSE
		vUsernames := (SELECT ARRAY_AGG(REPLACE(dt::TEXT, '"')) FROM JSON_ARRAY_ELEMENTS(vUsername) AS dt);
		vUsernames := vUsernames || ''::VARCHAR;
	END IF;
	--VERIFICAR QUE LAS REGLAS DE GEOTAB ESTÉN LLENAS
	IF (JSON_ARRAY_LENGTH(COALESCE(vGeotabRuleId, '[]')) <= 0) THEN
		vGeotabRules := (SELECT ARRAY_AGG(DISTINCT COALESCE(geotab_rule_id, '')) FROM command_logs WHERE date_time BETWEEN vFromDate AND vToDate);
	ELSE
		vGeotabRules := (SELECT ARRAY_AGG(REPLACE(dt::TEXT, '"')) FROM JSON_ARRAY_ELEMENTS(vGeotabRuleId) AS dt);
		vGeotabRules := vGeotabRules || ''::VARCHAR;
	END IF;
	--REGRESAR EL RESULTADO CORRECTO
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	vResult.data := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
							 FROM
							 (
								 SELECT ct.command_type_id AS "commandTypeId",
								 CASE WHEN ctt.name IS NULL THEN ct.name ELSE ctt.name END AS "commandName",
								 COALESCE(cl.geotab_rule_id, '') AS "geotabRuleId",
								 COALESCE(cl.username, '') AS "username",
								 cl.date_time AS "dateTime",
								 cl.geotab_go_id AS "geotabGoId"
								 FROM command_type AS ct
								 INNER JOIN command_logs AS cl
								 ON ct.command_type_id = cl.command_type_id
								 LEFT JOIN command_type_trans AS ctt
								 ON ct.command_type_id = ctt.command_type_id AND ctt.language_id = vLangId
								 WHERE cl.date_time BETWEEN vFromDate AND vToDate
								 AND COALESCE(username, '') IN (SELECT * FROM UNNEST(vUsernames))
								 AND COALESCE(geotab_rule_id, '') IN (SELECT * FROM UNNEST(vGeotabRules))
								 AND ct.command_type_id IN (SELECT * FROM UNNEST(vCommandTypes))
								 ORDER BY cl.date_time ASC
							 ) AS dt), '[]'::JSON);
	RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.command_log_select_fn(character varying, timestamp without time zone, timestamp without time zone, json, json, json)
    OWNER TO mmcam_dev;
