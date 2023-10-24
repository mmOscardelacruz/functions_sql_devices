-- FUNCTION: public.gbt_inet_picksplit(internal, internal)

-- DROP FUNCTION IF EXISTS public.gbt_inet_picksplit(internal, internal);

CREATE OR REPLACE FUNCTION public.gbt_inet_picksplit(
	internal,
	internal)
    RETURNS internal
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_inet_picksplit'
;

ALTER FUNCTION public.gbt_inet_picksplit(internal, internal)
    OWNER TO mmcam_dev;