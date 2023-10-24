-- FUNCTION: public.gbt_int4_fetch(internal)

-- DROP FUNCTION IF EXISTS public.gbt_int4_fetch(internal);

CREATE OR REPLACE FUNCTION public.gbt_int4_fetch(
	internal)
    RETURNS internal
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_int4_fetch'
;

ALTER FUNCTION public.gbt_int4_fetch(internal)
    OWNER TO mmcam_dev;
