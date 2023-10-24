-- FUNCTION: public.columns_array_select_fn(character varying)

-- DROP FUNCTION IF EXISTS public.columns_array_select_fn(character varying);

CREATE OR REPLACE FUNCTION public.columns_array_select_fn(
	vtablename character varying)
    RETURNS character varying[]
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	RETURN
	(
		SELECT ARRAY_AGG(column_name::TEXT)
		FROM information_schema.columns
		WHERE table_schema = 'public'
		AND table_name   = vTableName
		AND column_name NOT IN (SELECT field_name FROM excluded_unique_column)
		--SON LAS COLUMNAS CLAVE QUE NO SE DEBEN DE MODIFICAR. PUEDEN O NO ESTAR DENTRO DE LA TABLA POR LO QUE NO AFECTA SI SE BUSCA DE TRIP O EXCEPTIONEVENT
	);
END
$BODY$;

ALTER FUNCTION public.columns_array_select_fn(character varying)
    OWNER TO mmcam_dev;
