-- FUNCTION: public.gbt_macad_same(gbtreekey16, gbtreekey16, internal)

-- DROP FUNCTION IF EXISTS public.gbt_macad_same(gbtreekey16, gbtreekey16, internal);

CREATE OR REPLACE FUNCTION public.gbt_macad_same(
	gbtreekey16,
	gbtreekey16,
	internal)
    RETURNS internal
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_macad_same'
;

ALTER FUNCTION public.gbt_macad_same(gbtreekey16, gbtreekey16, internal)
    OWNER TO mmcam_dev;
