-- FUNCTION: public.gbt_var_decompress(internal)

-- DROP FUNCTION IF EXISTS public.gbt_var_decompress(internal);

CREATE OR REPLACE FUNCTION public.gbt_var_decompress(
	internal)
    RETURNS internal
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_var_decompress'
;

ALTER FUNCTION public.gbt_var_decompress(internal)
    OWNER TO mmcam_dev;
