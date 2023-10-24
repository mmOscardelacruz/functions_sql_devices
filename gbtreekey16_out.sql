-- FUNCTION: public.gbtreekey16_out(gbtreekey16)

-- DROP FUNCTION IF EXISTS public.gbtreekey16_out(gbtreekey16);

CREATE OR REPLACE FUNCTION public.gbtreekey16_out(
	gbtreekey16)
    RETURNS cstring
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbtreekey_out'
;

ALTER FUNCTION public.gbtreekey16_out(gbtreekey16)
    OWNER TO mmcam_dev;
