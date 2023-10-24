-- FUNCTION: public.delete_vehicle_config(character varying, character varying)

-- DROP FUNCTION IF EXISTS public.delete_vehicle_config(character varying, character varying);

CREATE OR REPLACE FUNCTION public.delete_vehicle_config(
	vtoken character varying,
	vserialmdvr character varying)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
	declare
			vIdUser bigint;
			vUsername varchar;
			vResult tpResponse;
	begin
			vIdUser := checkValidToken(vToken);
				vUsername := (SELECT username FROM "user" WHERE id = vIdUser);
				DELETE FROM farec.vehicle_config where serialMDVR = vSerialMDVR;
				PERFORM auditlog_insert_fn(vIdUser::text, 'Configuracion Face Rec'::text, 'DELETE'::text, CONCAT('Delete de informacion', vSerialMDVR)::text);
		vResult.code := 200; vResult.status := true; vResult.message := NULL;
				RETURN TO_JSON(vResult);
	end;
	
$BODY$;

ALTER FUNCTION public.delete_vehicle_config(character varying, character varying)
    OWNER TO mmcam_dev;
