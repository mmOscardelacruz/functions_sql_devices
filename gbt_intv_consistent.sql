-- FUNCTION: public.gbt_intv_consistent(internal, interval, smallint, oid, internal)

-- DROP FUNCTION IF EXISTS public.gbt_intv_consistent(internal, interval, smallint, oid, internal);

CREATE OR REPLACE FUNCTION public.gbt_intv_consistent(
	internal,
	interval,
	smallint,
	oid,
	internal)
    RETURNS boolean
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_intv_consistent'
;

ALTER FUNCTION public.gbt_intv_consistent(internal, interval, smallint, oid, internal)
    OWNER TO mmcam_dev;
