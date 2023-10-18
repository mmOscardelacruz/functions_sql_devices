-- FUNCTION: public.check_user_alarm_permission_json(character varying, character varying)

-- DROP FUNCTION IF EXISTS public.check_user_alarm_permission_json(character varying, character varying);

CREATE OR REPLACE FUNCTION public.check_user_alarm_permission_json(
	vtoken character varying,
	vdownloadid character varying)
    RETURNS json
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
		(select row_to_json(vd)
		from (
				SELECT tvd.*, 
				(case when g.gpstime is not null then g.gpstime  else r.gpstime  end) as date_time
				FROM task_video_data AS tvd
				-- INNER JOIN vehicle_device AS vdev
				INNER JOIN vehicle_device AS vdev
				ON tvd.id_vehicle = vdev.vehicle_id
				INNER JOIN vehicle AS v
				ON vdev.vehicle_id = v.id
				left join geotabalarm g 
				on tvd.id_geotabalarm = g.id_geotabalarm 
				left join receivedalarm r 
				on tvd.id_alarm = r.id 
				WHERE v.IdFleet IN (SELECT * FROM UNNEST(vGroups))
				AND tvd.download_id LIKE vDownloadId
			) as vd limit 1);
END
$BODY$;

ALTER FUNCTION public.check_user_alarm_permission_json(character varying, character varying)
    OWNER TO mmcam_dev;
