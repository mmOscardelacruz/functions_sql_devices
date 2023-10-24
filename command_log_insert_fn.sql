-- FUNCTION: public.command_log_insert_fn(integer, timestamp without time zone, character varying, character varying, character varying)

-- DROP FUNCTION IF EXISTS public.command_log_insert_fn(integer, timestamp without time zone, character varying, character varying, character varying);

CREATE OR REPLACE FUNCTION public.command_log_insert_fn(
	vcommandtypeid integer,
	vdatetime timestamp without time zone,
	vgeotabruleid character varying DEFAULT ''::character varying,
	vsessiontoken character varying DEFAULT ''::character varying,
	vgeotabgoid character varying DEFAULT NULL::character varying)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vIdUser		BIGINT;
	vUsername	VARCHAR := NULL;
	vResult		tpResponse;
BEGIN
	IF (LENGTH(COALESCE(vGeotabRuleId, '')) <= 0 AND LENGTH(COALESCE(vSessionToken, '')) <= 0) THEN
		RAISE EXCEPTION 'Debe de asignar por lo menos el Id de la regla de Geotab o la sesión del usuario para continuar';
	END IF;
	IF (LENGTH(COALESCE(vGeotabRuleId, '')) > 0 AND LENGTH(COALESCE(vSessionToken, '')) > 0) THEN
		RAISE EXCEPTION 'Solo puede enviar o el token de sesión o el id de la regla en la misma petición';
	END IF;
	IF (LENGTH(COALESCE(vSessionToken, '')) > 0) THEN
		--VALIDAR EL TOKEN
		vIdUser := checkValidToken(vSessionToken);
		vUsername := (SELECT username FROM "user" WHERE Id = vIdUser);
	END IF;
	INSERT INTO command_logs (command_type_id, username, geotab_rule_id, date_time, geotab_go_id)
	VALUES (vCommandTypeId, vUsername, vGeotabRuleId, vDateTime, vGeotabGoId);
	--REGRESAR EL RESULTADO CORRECTO
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	vResult.data := TO_JSON(TRUE);
	RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.command_log_insert_fn(integer, timestamp without time zone, character varying, character varying, character varying)
    OWNER TO mmcam_dev;
