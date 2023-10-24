-- FUNCTION: public.gbtreekey32_out(gbtreekey32)

-- DROP FUNCTION IF EXISTS public.gbtreekey32_out(gbtreekey32);

CREATE OR REPLACE FUNCTION public.gbtreekey32_out(
	gbtreekey32)
    RETURNS cstring
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbtreekey_out'
;

ALTER FUNCTION public.gbtreekey32_out(gbtreekey32)
    OWNER TO mmcam_dev;
