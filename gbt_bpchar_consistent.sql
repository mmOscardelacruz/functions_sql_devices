-- FUNCTION: public.gbt_bpchar_consistent(internal, character, smallint, oid, internal)

-- DROP FUNCTION IF EXISTS public.gbt_bpchar_consistent(internal, character, smallint, oid, internal);

CREATE OR REPLACE FUNCTION public.gbt_bpchar_consistent(
	internal,
	character,
	smallint,
	oid,
	internal)
    RETURNS boolean
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_bpchar_consistent'
;

ALTER FUNCTION public.gbt_bpchar_consistent(internal, character, smallint, oid, internal)
    OWNER TO mmcam_dev;
