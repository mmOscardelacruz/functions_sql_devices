-- FUNCTION: public.check_group_data_fn(bigint)

-- DROP FUNCTION IF EXISTS public.check_group_data_fn(bigint);

CREATE OR REPLACE FUNCTION public.check_group_data_fn(
	vidfleet bigint)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vMessage TEXT := '';
	vGroups BIGINT[];
	vCount	INT;
BEGIN
	vGroups := group_branch_select_fn(vIdFleet);
	--VERIFICAR A LOS USUARIOS QUE HAY EN LOS GRUPOS
	vCount := (SELECT COUNT(DISTINCT IdUser) FROM user_fleet WHERE IdFleet IN (SELECT * FROM UNNEST(vGroups)));
	IF (vCount > 0) THEN vMessage := CONCAT(vMessage, 'Usuarios (', vCount, '), '); END IF;
	--VERIFICAR A LOS VEHÍCULOS EN EL LOS GRUPOS
	vCount := (SELECT COUNT(DISTINCT Id) FROM Vehicle WHERE IdFleet IN (SELECT * FROM UNNEST(vGroups)));
	IF (vCount > 0) THEN vMessage := CONCAT(vMessage, 'Vehículos (', vCount, '), '); END IF; 
	--VERIFICAR REGLAS
	vCount := (SELECT COUNT(DISTINCT IdRule) FROM RuleByGroup WHERE IdFleet IN (SELECT * FROM UNNEST(vGroups)));
	IF (vCount > 0) THEN vMessage := CONCAT(vMessage, 'Reglas (', vCount, '), '); END IF;
	--VERIFICAR LOS GRUPOS
	vCount := (SELECT COUNT(DISTINCT Id) FROM Fleet WHERE Id IN (SELECT * FROM UNNEST(vGroups)) AND Id <> vIdFleet);
	IF(vCount > 0) THEN vMessage := CONCAT(vMessage, 'Grupos (', vCount, '), '); END IF;
	IF (LENGTH(vMessage) > 0) THEN vMessage := LEFT(vMessage, LENGTH(vMessage) - 2); END IF;
	RETURN vMessage;
END
$BODY$;

ALTER FUNCTION public.check_group_data_fn(bigint)
    OWNER TO mmcam_dev;
