-- FUNCTION: public.geotab_alarm_insert_fn(json)

-- DROP FUNCTION IF EXISTS public.geotab_alarm_insert_fn(json);

CREATE OR REPLACE FUNCTION public.geotab_alarm_insert_fn(
	vdata json)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
  BEGIN
    IF (JSON_ARRAY_LENGTH(COALESCE(vData, '[]'::JSON)) <= 0) THEN
      RAISE EXCEPTION 'DEBE DE ENVIAR POR LO MENOS UN REGISTRO PARA CONTINUAR';
    END IF;
    
    INSERT INTO geotabalarm (id_geotabruleserial, id_vehicle, geotab_go_rule, geotab_go_id, geotab_id_driver, duration, altitude, direction, gpstime, gpslat, gpslng, speed, recordspeed, state, type, content, cmdtype, creationdate, geotab_driver_name)
    SELECT (dt->>'geotabRuleSerialId')::BIGINT, (dt->>'vehicleId')::BIGINT, dt->>'geotabGoRule', 
    dt->>'geotabGoId', dt->>'geotabDriverId', (dt->>'duration')::INTERVAL, (dt->>'altitude')::FLOAT, 
    (dt->>'direction')::FLOAT, (dt->>'gpsTime')::TIMESTAMP(0), (dt->>'gpsLat')::FLOAT, (dt->>'gpsLng')::FLOAT, 
    (dt->>'speed')::FLOAT, (dt->>'recordSpeed')::FLOAT, -1, -1, '', -1, NOW(), dt->>'geotabDriverName'
    FROM JSON_ARRAY_ELEMENTS(vData) AS dt
    ON CONFLICT ON CONSTRAINT geotab_alarm_un
    DO NOTHING;
    
  END
  
$BODY$;

ALTER FUNCTION public.geotab_alarm_insert_fn(json)
    OWNER TO mmcam_dev;
