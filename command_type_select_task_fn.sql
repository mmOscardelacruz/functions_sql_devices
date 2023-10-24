-- FUNCTION: public.command_type_select_task_fn()

-- DROP FUNCTION IF EXISTS public.command_type_select_task_fn();

CREATE OR REPLACE FUNCTION public.command_type_select_task_fn(
	)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vResult		tpResponse;
BEGIN
	--REGRESAR EL RESULTADO CORRECTO
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	vResult.data := COALESCE((SELECT ARRAY_TO_JSON(ARRAY_AGG(dt)) 
							 FROM
							 (
								 SELECT ct.command_type_id AS "commandTypeId", ct.name
								 FROM command_type AS ct
								 ORDER BY 2 ASC
							 ) AS dt), '[]'::JSON);
	RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.command_type_select_task_fn()
    OWNER TO mmcam_dev;
