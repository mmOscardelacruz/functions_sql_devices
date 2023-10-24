-- FUNCTION: public.gbt_time_distance(internal, time without time zone, smallint, oid, internal)

-- DROP FUNCTION IF EXISTS public.gbt_time_distance(internal, time without time zone, smallint, oid, internal);

CREATE OR REPLACE FUNCTION public.gbt_time_distance(
	internal,
	time without time zone,
	smallint,
	oid,
	internal)
    RETURNS double precision
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_time_distance'
;

ALTER FUNCTION public.gbt_time_distance(internal, time without time zone, smallint, oid, internal)
    OWNER TO mmcam_dev;
