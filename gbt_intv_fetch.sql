-- FUNCTION: public.gbt_intv_fetch(internal)

-- DROP FUNCTION IF EXISTS public.gbt_intv_fetch(internal);

CREATE OR REPLACE FUNCTION public.gbt_intv_fetch(
	internal)
    RETURNS internal
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_intv_fetch'
;

ALTER FUNCTION public.gbt_intv_fetch(internal)
    OWNER TO mmcam_dev;
