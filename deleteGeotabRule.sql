-- FUNCTION: public.deleteGeotabRule(integer, character varying)

-- DROP FUNCTION IF EXISTS public."deleteGeotabRule"(integer, character varying);

CREATE OR REPLACE FUNCTION public."deleteGeotabRule"(
	vidgeotabruleserial integer,
	vtoken character varying)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
	declare
		vIdUser		BIGINT;
		vIdUsers 	BIGINT[];
		vData		RECORD;
		vUsername	TEXT;
		vUserLng	INT;
		vIdRule INT;
		vName varchar;
		vRuleName varchar;
	begin
			vIdUser := checkValidToken(vToken);
			--vIdUser := vToken::int; --fines de testeo
			vUsername := (SELECT username FROM "user" WHERE id = vIdUser);
			vRuleName := (SELECT name FROM GeotabRule where id_geotabRuleSerial = vidGeotabRuleSerial);
			--OBTENER EL IDIOMA DEL USUARIO
			vUserLng := (SELECT language_id FROM userconfig WHERE IdUser = vIdUser);
		IF (vidGeotabRuleSerial IS NULL) THEN
			RAISE EXCEPTION '%', message_select_fn(12, 4, vUserLng, 1, '{}'::VARCHAR[]);
		END IF;
		IF ((SELECT Id_User FROM GeotabRule WHERE id_GeotabRuleSerial = vidGeotabRuleSerial) <> vIdUser AND NOT(SELECT is_Public FROM GeotabRule WHERE id_GeotabRuleSerial = vidGeotabRuleSerial)) THEN
			RAISE EXCEPTION '%', message_select_fn(12, 4, vUserLng, 2, '{}'::VARCHAR[]);
		END IF;
		--ELIMINACIÓN DE EMAILS POR REGLA
		DELETE FROM EmailByGeotabRule WHERE id_GeotabRuleSerial = vidGeotabRuleSerial;
		--ELIMINACIÓN DE VEHÍCULOS POR REGLA
		DELETE FROM GeotabRuleByVehicle WHERE id_GeotabRuleSerial = vidGeotabRuleSerial;
		--ELIMINACIÓN DE GRUPOS POR REGLA
		DELETE FROM GeotabRuleByGroup WHERE id_GeotabRuleSerial = vidGeotabRuleSerial;
		--AUDIT LOG
		vName := (SELECT name FROM GeotabRule WHERE id_GeotabRuleSerial = vidGeotabRuleSerial);
		PERFORM auditlog_insert_fn(vUsername, 'Reglas MyGeotab', 'Eliminación de reglas', CONCAT('Eliminó la regla ', vRuleName));
		--ELIMINACIÓN DE REGLA
		DELETE FROM GeotabRule WHERE id_GeotabRuleSerial = vidGeotabRuleSerial;
		return true;
	end;
	
$BODY$;

ALTER FUNCTION public."deleteGeotabRule"(integer, character varying)
    OWNER TO mmcam_dev;
