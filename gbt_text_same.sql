-- FUNCTION: public.gbt_text_same(gbtreekey_var, gbtreekey_var, internal)

-- DROP FUNCTION IF EXISTS public.gbt_text_same(gbtreekey_var, gbtreekey_var, internal);

CREATE OR REPLACE FUNCTION public.gbt_text_same(
	gbtreekey_var,
	gbtreekey_var,
	internal)
    RETURNS internal
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_text_same'
;

ALTER FUNCTION public.gbt_text_same(gbtreekey_var, gbtreekey_var, internal)
    OWNER TO mmcam_dev;
