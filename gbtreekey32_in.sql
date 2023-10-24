-- FUNCTION: public.gbtreekey32_in(cstring)

-- DROP FUNCTION IF EXISTS public.gbtreekey32_in(cstring);

CREATE OR REPLACE FUNCTION public.gbtreekey32_in(
	cstring)
    RETURNS gbtreekey32
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbtreekey_in'
;

ALTER FUNCTION public.gbtreekey32_in(cstring)
    OWNER TO mmcam_dev;
