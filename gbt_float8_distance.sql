-- FUNCTION: public.gbt_float8_distance(internal, double precision, smallint, oid, internal)

-- DROP FUNCTION IF EXISTS public.gbt_float8_distance(internal, double precision, smallint, oid, internal);

CREATE OR REPLACE FUNCTION public.gbt_float8_distance(
	internal,
	double precision,
	smallint,
	oid,
	internal)
    RETURNS double precision
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_float8_distance'
;

ALTER FUNCTION public.gbt_float8_distance(internal, double precision, smallint, oid, internal)
    OWNER TO mmcam_dev;
