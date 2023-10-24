-- FUNCTION: public.converttoutctime(timestamp without time zone, character varying)

-- DROP FUNCTION IF EXISTS public.converttoutctime(timestamp without time zone, character varying);

CREATE OR REPLACE FUNCTION public.converttoutctime(
	vvalue timestamp without time zone,
	voffset character varying)
    RETURNS timestamp without time zone
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
operador varchar;
hrs int;
mins int;
begin
	if((select substring(vOffset from 1 for 1)) = '-'::TEXT) then
		hrs := (select substring(vOffset from 2 for 1));
		mins := (select substring(vOffset from 4 for 2));
		return vValue + (SELECT CONCAT(hrs,' hr'))::INTERVAL + (SELECT CONCAT(mins,' min'))::INTERVAL;
	else
		hrs := (select substring(vOffset from 1 for 1));
		mins := (select substring(vOffset from 3 for 2));
		return vValue - (SELECT CONCAT(hrs,' hr'))::INTERVAL - (SELECT CONCAT(mins,' min'))::INTERVAL;
	end if;
	
end
$BODY$;

ALTER FUNCTION public.converttoutctime(timestamp without time zone, character varying)
    OWNER TO mmcam_dev;
