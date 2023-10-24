-- FUNCTION: public.gbt_inet_consistent(internal, inet, smallint, oid, internal)

-- DROP FUNCTION IF EXISTS public.gbt_inet_consistent(internal, inet, smallint, oid, internal);

CREATE OR REPLACE FUNCTION public.gbt_inet_consistent(
	internal,
	inet,
	smallint,
	oid,
	internal)
    RETURNS boolean
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_inet_consistent'
;

ALTER FUNCTION public.gbt_inet_consistent(internal, inet, smallint, oid, internal)
    OWNER TO mmcam_dev;
