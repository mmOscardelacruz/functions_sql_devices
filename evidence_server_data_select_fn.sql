-- FUNCTION: public.evidence_server_data_select_fn()

-- DROP FUNCTION IF EXISTS public.evidence_server_data_select_fn();

CREATE OR REPLACE FUNCTION public.evidence_server_data_select_fn(
	)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	RETURN
	COALESCE((
		(
			SELECT JSON_BUILD_OBJECT('evidenceUrl', evidence_url) FROM evidence_server LIMIT 1
		)
	), '{}'::JSON);
END
$BODY$;

ALTER FUNCTION public.evidence_server_data_select_fn()
    OWNER TO mmcam_dev;
