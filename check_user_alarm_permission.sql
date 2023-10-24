-- FUNCTION: public.check_user_alarm_permission(character varying, character varying)

-- DROP FUNCTION IF EXISTS public.check_user_alarm_permission(character varying, character varying);

CREATE OR REPLACE FUNCTION public.check_user_alarm_permission(
	vtoken character varying,
	vdownloadid character varying)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vIdUser	BIGINT;
	vGroups	BIGINT[];
BEGIN
	--CHEQUEO DE SESIÓN (SESIÓN VÁLIDA) Y OBTENCIÓN DE ID
	vIdUser := CheckValidToken(vToken);
	--OBTENCIÓN LOS GRUPOS
	vGroups := getPlainGroupsAll(vIdUser);
	--VERIFICAR SI EL USUARIO TIENE ACCESO AL DOWNLOAD ID
	RETURN
	EXISTS(
		SELECT * FROM task_video_data AS tvd
		INNER JOIN vehicle AS v
		ON tvd.id_vehicle = v.id
		WHERE v.IdFleet IN (SELECT * FROM UNNEST(vGroups))
		AND tvd.download_id LIKE vDownloadId
	);
END
$BODY$;

ALTER FUNCTION public.check_user_alarm_permission(character varying, character varying)
    OWNER TO mmcam_dev;
