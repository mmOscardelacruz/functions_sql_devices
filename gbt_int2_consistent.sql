-- FUNCTION: public.gbt_int2_consistent(internal, smallint, smallint, oid, internal)

-- DROP FUNCTION IF EXISTS public.gbt_int2_consistent(internal, smallint, smallint, oid, internal);

CREATE OR REPLACE FUNCTION public.gbt_int2_consistent(
	internal,
	smallint,
	smallint,
	oid,
	internal)
    RETURNS boolean
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_int2_consistent'
;

ALTER FUNCTION public.gbt_int2_consistent(internal, smallint, smallint, oid, internal)
    OWNER TO mmcam_dev;
