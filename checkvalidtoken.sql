-- FUNCTION: public.checkvalidtoken(text)

-- DROP FUNCTION IF EXISTS public.checkvalidtoken(text);

CREATE OR REPLACE FUNCTION public.checkvalidtoken(
	vtoken text)
    RETURNS bigint
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vIdUser 	BIGINT;
	vData		RECORD;
	vTimeLeft	INTERVAL;
BEGIN
	IF NOT EXISTS (SELECT * FROM SessionManagement WHERE SessionT LIKE vToken) THEN
		RAISE EXCEPTION '01';
	END IF;
	vData := (SELECT tbData FROM SessionManagement AS tbData WHERE SessionT LIKE vToken ORDER BY Datetime DESC LIMIT 1);
	--RAISE NOTICE '%', vData.IsActive;
	IF NOT(vData.IsActive) THEN
		RAISE EXCEPTION '02';
	END IF;
	RAISE NOTICE '%', ((INTERVAL '24H' - vTimeLeft) + vData.ExpirationD);
	IF ( vTimeLeft < INTERVAL '24H') THEN
		UPDATE SessionManagement SET ExpirationD = vData.ExpirationD + (INTERVAL '24H' - vTimeLeft) WHERE SessionT LIKE vToken;
	END IF;
	IF (vData.ExpirationD < NOW()) THEN
		RAISE EXCEPTION '03';
	END IF;
	RETURN vData.IdUser;
END
$BODY$;

ALTER FUNCTION public.checkvalidtoken(text)
    OWNER TO mmcam_dev;
