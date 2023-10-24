-- FUNCTION: public.gbt_oid_consistent(internal, oid, smallint, oid, internal)

-- DROP FUNCTION IF EXISTS public.gbt_oid_consistent(internal, oid, smallint, oid, internal);

CREATE OR REPLACE FUNCTION public.gbt_oid_consistent(
	internal,
	oid,
	smallint,
	oid,
	internal)
    RETURNS boolean
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_oid_consistent'
;

ALTER FUNCTION public.gbt_oid_consistent(internal, oid, smallint, oid, internal)
    OWNER TO mmcam_dev;
