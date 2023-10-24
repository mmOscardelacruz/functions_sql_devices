-- FUNCTION: public.gbt_ts_consistent(internal, timestamp without time zone, smallint, oid, internal)

-- DROP FUNCTION IF EXISTS public.gbt_ts_consistent(internal, timestamp without time zone, smallint, oid, internal);

CREATE OR REPLACE FUNCTION public.gbt_ts_consistent(
	internal,
	timestamp without time zone,
	smallint,
	oid,
	internal)
    RETURNS boolean
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_ts_consistent'
;

ALTER FUNCTION public.gbt_ts_consistent(internal, timestamp without time zone, smallint, oid, internal)
    OWNER TO mmcam_dev;
