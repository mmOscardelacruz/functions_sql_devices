-- FUNCTION: public.gbtreekey4_out(gbtreekey4)

-- DROP FUNCTION IF EXISTS public.gbtreekey4_out(gbtreekey4);

CREATE OR REPLACE FUNCTION public.gbtreekey4_out(
	gbtreekey4)
    RETURNS cstring
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbtreekey_out'
;

ALTER FUNCTION public.gbtreekey4_out(gbtreekey4)
    OWNER TO mmcam_dev;
