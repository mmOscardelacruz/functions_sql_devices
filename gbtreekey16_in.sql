-- FUNCTION: public.gbtreekey16_in(cstring)

-- DROP FUNCTION IF EXISTS public.gbtreekey16_in(cstring);

CREATE OR REPLACE FUNCTION public.gbtreekey16_in(
	cstring)
    RETURNS gbtreekey16
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbtreekey_in'
;

ALTER FUNCTION public.gbtreekey16_in(cstring)
    OWNER TO mmcam_dev;
