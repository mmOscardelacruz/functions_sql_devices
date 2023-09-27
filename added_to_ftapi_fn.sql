-- DROP FUNCTION IF EXISTS public.added_to_ftapi_fn(character varying);

CREATE OR REPLACE FUNCTION public.added_to_ftapi_fn(
	vserialmdvr character varying)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vResponse	tpResponse;
BEGIN
	vResponse.code := 200; vResponse.status := TRUE; vResponse.message := '';
	
	IF NOT EXISTS(SELECT * FROM vehicle WHERE serialmdvr = vSerialMDVR) THEN
		vResponse.code := 404;
		vResponse.status := FALSE;
		vResponse.message := 'El Vehículo no existe';
		RETURN TO_JSON(vResponse);
	END IF;
	UPDATE vehicle SET is_on_ftapi = TRUE
	WHERE serialmdvr = vSerialMDVR;
	vResponse.data := TO_JSON(TRUE);
	RETURN TO_JSON(vResponse);
END
$BODY$;