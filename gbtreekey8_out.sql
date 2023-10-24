-- FUNCTION: public.gbtreekey8_out(gbtreekey8)

-- DROP FUNCTION IF EXISTS public.gbtreekey8_out(gbtreekey8);

CREATE OR REPLACE FUNCTION public.gbtreekey8_out(
	gbtreekey8)
    RETURNS cstring
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbtreekey_out'
;

ALTER FUNCTION public.gbtreekey8_out(gbtreekey8)
    OWNER TO mmcam_dev;
