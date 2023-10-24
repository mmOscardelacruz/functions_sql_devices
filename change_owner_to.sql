-- FUNCTION: public.change_owner_to(text)

-- DROP FUNCTION IF EXISTS public.change_owner_to(text);

CREATE OR REPLACE FUNCTION public.change_owner_to(
	vnewowner text)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vTName	VARCHAR;
	vQuery	VARCHAR;
BEGIN
	FOR vTName IN (SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' ORDER BY 1 ASC) LOOP
		vQuery := 'ALTER TABLE ' || QUOTE_IDENT(vTName) || ' OWNER TO ' || QUOTE_IDENT(vNewOwner);
		RAISE NOTICE 'TABLA: % | %', vTName, vQuery; 
		EXECUTE vQuery;
	END LOOP;
END
$BODY$;

ALTER FUNCTION public.change_owner_to(text)
    OWNER TO mmcam_dev;
