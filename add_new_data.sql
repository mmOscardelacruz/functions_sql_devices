CREATE OR REPLACE FUNCTION public.add_new_data(
	vserial character varying,
	vdate timestamp without time zone)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vFromDate			TIMESTAMP(0);
	vToDate				TIMESTAMP(0);
	vPartitionName		VARCHAR := 'date_partition_test'; --NOMBRE DE LA TABLA LA QUE PARTICIONAREMOS
BEGIN
	--OBTENER LAS FECHAS DE INICIO Y FIN DEPENDIENDO DE LA FECHA QUE ENVÍE EL USUARIO
	vFromDate := TO_CHAR(vDate, 'YYYY-MM-01 00:00:00')::TIMESTAMP(0);
	vToDate := vFromDate + INTERVAL '1Month';
	-- VERIFICAR QUE NO EXISTA UNA TABLA CON EL NOMBRE DE LA PARTICIÓN A CREAR
	IF NOT EXISTS (SELECT * FROM information_schema.tables WHERE table_schema = 'public' AND table_name = vPartitionName || TO_CHAR(vFromDate, '_YYYY_MM')) THEN
		--CREAR TABLA QUE HEREDE LAS PROPIEDADES DE LA TABLA PRINCIPAL
		EXECUTE 'CREATE TABLE ' || QUOTE_IDENT(vPartitionName || TO_CHAR(vFromDate,'_YYYY_MM')) || ' ( CHECK(date >=  ' || QUOTE_LITERAL(vFromDate) || ' AND date < ' || QUOTE_LITERAL(vToDate) || ')) INHERITS (' || vPartitionName || ')';
		--CREAR LA INDEXACIÓN DE LA TABLA
		EXECUTE 'CREATE INDEX ' || QUOTE_IDENT(vPartitionName || TO_CHAR(vFromDate,'_YYYY_MM')) || '_index ON ' || QUOTE_IDENT(vPartitionName || TO_CHAR(vFromDate,'_YYYY_MM')) || '(serial, date)';
		--CREAR UNA CONSTRAINT CON DATOS QUE NO SE VAYAN A REPETIR
		EXECUTE 'ALTER TABLE ' || QUOTE_IDENT(vPartitionName || TO_CHAR(vFromDate,'_YYYY_MM')) || ' ADD CONSTRAINT ' || QUOTE_IDENT(vPartitionName || TO_CHAR(vFromDate,'_YYYY_MM')) || '_pk PRIMARY KEY(serial, date);';
	END IF;
	--INSERTAR DATOS EN LA PARTICIÓN
	EXECUTE 
	'
		INSERT INTO ' || vPartitionName || TO_CHAR(vFromDate, '_YYYY_MM') || ' (serial, date) VALUES (' || QUOTE_LITERAL(vSerial) || ', ' || QUOTE_LITERAL(vDate) ||')
		ON CONFLICT ON CONSTRAINT ' || QUOTE_IDENT(vPartitionName || TO_CHAR(vFromDate,'_YYYY_MM')) || '_pk 
		DO NOTHING
	';
END
$BODY$;