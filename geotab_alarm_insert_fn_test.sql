-- FUNCTION: public.geotab_alarm_insert_fn_test(json)

-- DROP FUNCTION IF EXISTS public.geotab_alarm_insert_fn_test(json);

CREATE OR REPLACE FUNCTION public.geotab_alarm_insert_fn_test(
	vdata json)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vLocalTime					TIMESTAMP(0);
	vFromDate					TIMESTAMP(0);
	vToDate						TIMESTAMP(0);
	vPartitionName				VARCHAR := 'geotabalarm_test';
	
BEGIN
-- 	OBTENER FECHAS DE PARTICIONADO.
	vLocalTime := NOW();
	vFromDate := (SELECT DATE_TRUNC('MONTH' ,vLocalTime));
	vToDate := (vFromDate + INTERVAL '1MONTH') - INTERVAL '1S';
	
-- 	VERIFICAR QUE EXISTAN DATOS PARA INSERTAR.
	IF (JSON_ARRAY_LENGTH(COALESCE(vData, '[]'::JSON)) <= 0) THEN
		RAISE EXCEPTION 'El arreglo debe contener almenos un registro.';
	END IF;
	
-- 	VERIFICAR QUE EXISTA LA PARTICION, SI NO EXISTE, SE CREA.
	IF NOT EXISTS (SELECT RELNAME FROM PG_CLASS WHERE UPPER(RELNAME) = UPPER(vPartitionName || TO_CHAR(vFromDate, '_YYYY_MM'))) THEN
		RAISE NOTICE 'No existe la particion, hay que crearla.';

		--CREAR TABLA.
		EXECUTE 'CREATE TABLE ' || (vPartitionName || TO_CHAR(vFromDate, '_YYYY_MM')) || ' (LIKE ' || (vPartitionName) || ' INCLUDING ALL);';

		--CREAR SU CHECK PARA LAS PARTICIONES
		EXECUTE 'ALTER TABLE ' || (vPartitionName || TO_CHAR(vFromDate, '_YYYY_MM')) || '
		 ADD CONSTRAINT ' || (vPartitionName || TO_CHAR(vFromDate, '_YYYY_MM')) || '_chk
		 CHECK(gpstime >= ' || QUOTE_LITERAL(vFromDate) || ' AND gpstime <= ' || QUOTE_LITERAL(vToDate) || ');';

		--CREAR SU INDEX.
		EXECUTE 'CREATE INDEX ' || (vPartitionName || TO_CHAR(vFromDate, '_YYYY_MM')) || '_index ON '
		|| (vPartitionName || TO_CHAR(vFromDate, '_YYYY_MM')) ||
		' (id_geotabalarm, id_vehicle, gpstime, geotab_id_driver)';

		--VINCULAR LA TABLA PARTICIONADA A LA TABLA PRINCIPAL.
		EXECUTE 'ALTER TABLE ' || (vPartitionName) || ' ATTACH PARTITION ' || (vPartitionName || TO_CHAR(vFromDate, '_YYYY_MM')) || '
		FOR VALUES FROM (' || QUOTE_LITERAL(vFromDate)||') TO (' || QUOTE_LITERAL(vToDate) ||');';

		RAISE NOTICE 'Se ha creado la particion: %', vPartitionName || TO_CHAR(vFromDate, '_YYYY_MM');
	END IF;
	
-- 	INSERTAR DATOS A LA TABLA.
    INSERT INTO geotabalarm_test (id_geotabruleserial, id_vehicle, geotab_go_rule, geotab_go_id, geotab_id_driver, duration, 
							 altitude, direction, gpstime, gpslat, gpslng, speed, recordspeed, state, type, content, 
							 cmdtype, creationdate, geotab_driver_name)
    SELECT (dt->>'geotabRuleSerialId')::BIGINT, (dt->>'vehicleId')::BIGINT, dt->>'geotabGoRule', 
    dt->>'geotabGoId', dt->>'geotabDriverId', (dt->>'duration')::INTERVAL, (dt->>'altitude')::FLOAT, 
    (dt->>'direction')::FLOAT, (dt->>'gpsTime')::TIMESTAMP(0), (dt->>'gpsLat')::FLOAT, (dt->>'gpsLng')::FLOAT, 
    (dt->>'speed')::FLOAT, (dt->>'recordSpeed')::FLOAT, -1, -1, '', -1, NOW(), dt->>'geotabDriverName'
    FROM JSON_ARRAY_ELEMENTS(vData) AS dt
    ON CONFLICT ON CONSTRAINT geotabalarm_test_pk DO NOTHING;
	
END 
$BODY$;

ALTER FUNCTION public.geotab_alarm_insert_fn_test(json)
    OWNER TO mmcam_dev;
