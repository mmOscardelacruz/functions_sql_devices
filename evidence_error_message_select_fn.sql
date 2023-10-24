-- FUNCTION: public.evidence_error_message_select_fn(character varying, character varying, integer)

-- DROP FUNCTION IF EXISTS public.evidence_error_message_select_fn(character varying, character varying, integer);

CREATE OR REPLACE FUNCTION public.evidence_error_message_select_fn(
	vstate character varying,
	vsubstate character varying,
	vlangid integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	IF (vState IS NULL) THEN
		RETURN (SELECT CASE WHEN eet.message IS NULL THEN ee.message ELSE eet.message END 
				FROM evidence_error AS ee
			   	LEFT JOIN evidence_error_trans AS eet
			   	ON ee.evidence_error_id = eet.evidence_error_id
			   	AND eet.language_id = vLangId
			   	WHERE ee.state IS NULL AND ee.substate IS NULL);
	END IF;
	RETURN
	(
		SELECT CASE WHEN eet.message IS NULL THEN ee.message ELSE eet.message END 
		FROM evidence_error AS ee
		LEFT JOIN evidence_error_trans AS eet
		ON ee.evidence_error_id = eet.evidence_error_id
		AND eet.language_id = vLangId
		WHERE ee.state LIKE vState AND ee.substate LIKE vSubState
	);
END
$BODY$;

ALTER FUNCTION public.evidence_error_message_select_fn(character varying, character varying, integer)
    OWNER TO mmcam_dev;
