-- FUNCTION: public.gbt_int4_penalty(internal, internal, internal)

-- DROP FUNCTION IF EXISTS public.gbt_int4_penalty(internal, internal, internal);

CREATE OR REPLACE FUNCTION public.gbt_int4_penalty(
	internal,
	internal,
	internal)
    RETURNS internal
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_int4_penalty'
;

ALTER FUNCTION public.gbt_int4_penalty(internal, internal, internal)
    OWNER TO mmcam_dev;
