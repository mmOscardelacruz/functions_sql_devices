-- FUNCTION: public.gbt_intv_same(gbtreekey32, gbtreekey32, internal)

-- DROP FUNCTION IF EXISTS public.gbt_intv_same(gbtreekey32, gbtreekey32, internal);

CREATE OR REPLACE FUNCTION public.gbt_intv_same(
	gbtreekey32,
	gbtreekey32,
	internal)
    RETURNS internal
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_intv_same'
;

ALTER FUNCTION public.gbt_intv_same(gbtreekey32, gbtreekey32, internal)
    OWNER TO mmcam_dev;
