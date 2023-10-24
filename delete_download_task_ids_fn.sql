-- FUNCTION: public.delete_download_task_ids_fn()

-- DROP FUNCTION IF EXISTS public.delete_download_task_ids_fn();

CREATE OR REPLACE FUNCTION public.delete_download_task_ids_fn(
	)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	DELETE FROM geotab_download_task;
	DELETE FROM streamax_download_task;
END
$BODY$;

ALTER FUNCTION public.delete_download_task_ids_fn()
    OWNER TO mmcam_dev;
