-- FUNCTION: public.geotab_alarm_data_for_rule(bigint, bigint, interval)

-- DROP FUNCTION IF EXISTS public.geotab_alarm_data_for_rule(bigint, bigint, interval);

CREATE OR REPLACE FUNCTION public.geotab_alarm_data_for_rule(
	vgeotabruleid bigint,
	vuserid bigint,
	voffset interval)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vLangId	INT;
BEGIN
	vLangId := (SELECT language_id FROM userconfig WHERE iduser = vUserId LIMIT 1);
	RETURN
	(SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
	 FROM
	 (
		 SELECT dt.*, task_video_data_select_fn(dt."idVehicle", dt."idRecAl", NULL) AS "evidence", evidence_error_fn(dt."idRecAl", 'geotab', vLangId) AS "evidenceError"
		 FROM
		 (
			 SELECT ga.id_geotabalarm AS "idRecAl", ga.gpslat, ga.gpslng, ga.gpstime + vOffset AS "gpstime",
			 ga.gpstime AS "gpstimeUtc",
			 F.name AS "groupName", v.name AS "vehicleName", v.platenumber AS "plateNumber", v.model AS "vehicleModel",
			 v.comments AS "comments",
			 (SELECT gif_required FROM geotabrule WHERE id_geotabruleserial = vGeotabRuleId) AS "gifRequired",
			 (SELECT video_required FROM geotabrule WHERE id_geotabruleserial = vGeotabRuleId) AS "videoRequired",
			 v.serialmdvr AS "serial", v.Id AS "idVehicle"
			 FROM geotabalarm AS ga
			 INNER JOIN vehicle AS v
			 ON ga.id_vehicle = v.id
			 INNER JOIN Fleet AS f
			 ON v.idFleet = f.Id
			 INNER JOIN attendgeotabalarm AS aga
			 ON ga.id_geotabalarm = aga.id_geotabalarm
			 WHERE ga.id_geotabruleserial = vGeotabRuleId
			 AND aga.date_sent_email IS NULL
			 AND aga.id_user = vUserId
			 GROUP BY ga.id_geotabalarm, ga.gpslat, ga.gpslng, ga.gpstime, f.name, v.platenumber, v.model,
			 v.comments, v.serialmdvr, v.Id, v.name
			 ORDER BY ga.gpstime DESC
		 ) AS dt
	 ) AS dt);
END
$BODY$;

ALTER FUNCTION public.geotab_alarm_data_for_rule(bigint, bigint, interval)
    OWNER TO mmcam_dev;
