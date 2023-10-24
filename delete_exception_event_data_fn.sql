-- FUNCTION: public.delete_exception_event_data_fn(timestamp without time zone, timestamp without time zone)

-- DROP FUNCTION IF EXISTS public.delete_exception_event_data_fn(timestamp without time zone, timestamp without time zone);

CREATE OR REPLACE FUNCTION public.delete_exception_event_data_fn(
	vfromdate timestamp without time zone,
	vtodate timestamp without time zone)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	IF (vFromDate > vToDate) THEN
		RAISE EXCEPTION 'LA FECHA DE INICIO NO PUEDE SER MAYOR A LA FECHA FIN';
	END IF;
	IF (vToDate >= NOW()) THEN
		RAISE EXCEPTION 'LA FECHA FIN NO PUEDE SER MAYOR O IGUAL A LA FECHA ACTUAL';
	END IF;
	IF ((NOW() - vToDate) < INTERVAL '7D' ) THEN
		RAISE EXCEPTION 'LA FECHA FIN TIENE QUE TENER UN PERIODO MAYOR O IGUAL A 7 DÍAS DE LA FECHA ACTUAL';
	END IF;
	DELETE FROM exception_event WHERE active_from BETWEEN vFromDate AND vToDate;
	--EXECUTE 'VACUUM FULL exception_event'; NO SE PUEDE EJECUTAR DENTRO DE UNA FUNCIÓN
END
$BODY$;

ALTER FUNCTION public.delete_exception_event_data_fn(timestamp without time zone, timestamp without time zone)
    OWNER TO mmcam_dev;
