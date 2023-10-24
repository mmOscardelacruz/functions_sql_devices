-- FUNCTION: public.gbt_text_union(internal, internal)

-- DROP FUNCTION IF EXISTS public.gbt_text_union(internal, internal);

CREATE OR REPLACE FUNCTION public.gbt_text_union(
	internal,
	internal)
    RETURNS gbtreekey_var
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_text_union'
;

ALTER FUNCTION public.gbt_text_union(internal, internal)
    OWNER TO mmcam_dev;
