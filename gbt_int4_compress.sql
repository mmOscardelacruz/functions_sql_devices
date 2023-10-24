-- FUNCTION: public.gbt_int4_compress(internal)

-- DROP FUNCTION IF EXISTS public.gbt_int4_compress(internal);

CREATE OR REPLACE FUNCTION public.gbt_int4_compress(
	internal)
    RETURNS internal
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_int4_compress'
;

ALTER FUNCTION public.gbt_int4_compress(internal)
    OWNER TO mmcam_dev;
