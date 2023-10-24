-- FUNCTION: public.createGeotabAlarm(character varying, character varying, character varying, character varying, time without time zone, double precision, double precision, timestamp without time zone, double precision, double precision, double precision, double precision, integer, timestamp without time zone, integer, character varying, integer)

-- DROP FUNCTION IF EXISTS public."createGeotabAlarm"(character varying, character varying, character varying, character varying, time without time zone, double precision, double precision, timestamp without time zone, double precision, double precision, double precision, double precision, integer, timestamp without time zone, integer, character varying, integer);

CREATE OR REPLACE FUNCTION public."createGeotabAlarm"(
	vgeotabgorule character varying,
	vgeotabgoid character varying,
	viddriver character varying,
	vidalarm character varying,
	vduration time without time zone,
	valtitude double precision,
	vdirection double precision,
	vgpstime timestamp without time zone,
	vgpslat double precision,
	vgpslng double precision,
	vspeed double precision,
	vrecordspeed double precision,
	vstate integer,
	vcreationdate timestamp without time zone,
	vtype integer,
	vcontent character varying,
	vcmdtype integer)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
	declare
	vIdGeotabRuleSerial BIGINT;
	vIdVehicle BIGINT;
	BEGIN
	vIdGeotabRuleSerial := (SELECT id_GeotabRuleSerial from GeotabRule where id_GeotabRule = vGeotabGoRule);
	vIdVehicle := (SELECT vehicle_id from vehicle_mdvr_go where geotab_go_id = vGeotabGoId);
		INSERT INTO GeotabAlarm (
			id_GeotabRuleSerial, 
			id_Vehicle,
			geotab_go_rule,
			geotab_go_id,
			geotab_id_Driver,
			geotab_id_Alarm, 
			duration,
			altitude,
			direction,
			gpsTime,
			gpslat,
			gpslng,
			speed,
			recordspeed,
			state,
			creationDate,
			type,
			content,
			cmdtype
			) values (
				vIdGeotabRuleSerial,
				vIdVehicle,
				vGeotabGoRule,
				vGeotabGoId,
				vidDriver,
				vidAlarm,
				vDuration,
				vAltitude,
				vDirection,
				vGpsTime,
				vGpsLat,
				vGpsLng,
				vSpeed,
				vRecordSpeed,
				vState,
				vCreationDate,
				vType,
				vContent,
				vcmdType
				 );
		return true;
	END
	
$BODY$;

ALTER FUNCTION public."createGeotabAlarm"(character varying, character varying, character varying, character varying, time without time zone, double precision, double precision, timestamp without time zone, double precision, double precision, double precision, double precision, integer, timestamp without time zone, integer, character varying, integer)
    OWNER TO mmcam_dev;
