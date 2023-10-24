-- FUNCTION: public.gbt_numeric_consistent(internal, numeric, smallint, oid, internal)

-- DROP FUNCTION IF EXISTS public.gbt_numeric_consistent(internal, numeric, smallint, oid, internal);

CREATE OR REPLACE FUNCTION public.gbt_numeric_consistent(
	internal,
	numeric,
	smallint,
	oid,
	internal)
    RETURNS boolean
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_numeric_consistent'
;

ALTER FUNCTION public.gbt_numeric_consistent(internal, numeric, smallint, oid, internal)
    OWNER TO mmcam_dev;
