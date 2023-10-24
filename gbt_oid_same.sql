-- FUNCTION: public.gbt_oid_same(gbtreekey8, gbtreekey8, internal)

-- DROP FUNCTION IF EXISTS public.gbt_oid_same(gbtreekey8, gbtreekey8, internal);

CREATE OR REPLACE FUNCTION public.gbt_oid_same(
	gbtreekey8,
	gbtreekey8,
	internal)
    RETURNS internal
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_oid_same'
;

ALTER FUNCTION public.gbt_oid_same(gbtreekey8, gbtreekey8, internal)
    OWNER TO mmcam_dev;
