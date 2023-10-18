-- FUNCTION: public.bug_test(json)

-- DROP FUNCTION IF EXISTS public.bug_test(json);

CREATE OR REPLACE FUNCTION public.bug_test(
	vdata json)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
cont int;
registros varchar[];
begin
registros = (SELECT ARRAY_AGG(REPLACE(dt->>'idGeotabAlarm'::TEXT, '"', '')) FROM JSON_ARRAY_ELEMENTS(vData) AS dt);
cont := 1;
	-- if not exists(select * from geotabalarm where id_geotabalarm = (select (dt->>'idGeotabAlarm')::bigint from JSON_ARRAY_ELEMENTS(vData) AS dt)) then
	
	raise notice '%', registros;
	
	cont = cont+1;
	-- end if;
end
$BODY$;

