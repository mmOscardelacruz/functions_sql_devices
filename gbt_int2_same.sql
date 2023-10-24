-- FUNCTION: public.gbt_int2_same(gbtreekey4, gbtreekey4, internal)

-- DROP FUNCTION IF EXISTS public.gbt_int2_same(gbtreekey4, gbtreekey4, internal);

CREATE OR REPLACE FUNCTION public.gbt_int2_same(
	gbtreekey4,
	gbtreekey4,
	internal)
    RETURNS internal
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_int2_same'
;

ALTER FUNCTION public.gbt_int2_same(gbtreekey4, gbtreekey4, internal)
    OWNER TO mmcam_dev;
