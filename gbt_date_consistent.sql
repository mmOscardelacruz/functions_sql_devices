-- FUNCTION: public.gbt_date_consistent(internal, date, smallint, oid, internal)

-- DROP FUNCTION IF EXISTS public.gbt_date_consistent(internal, date, smallint, oid, internal);

CREATE OR REPLACE FUNCTION public.gbt_date_consistent(
	internal,
	date,
	smallint,
	oid,
	internal)
    RETURNS boolean
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_date_consistent'
;

ALTER FUNCTION public.gbt_date_consistent(internal, date, smallint, oid, internal)
    OWNER TO mmcam_dev;
