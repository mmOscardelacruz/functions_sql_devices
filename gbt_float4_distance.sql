-- FUNCTION: public.gbt_float4_distance(internal, real, smallint, oid, internal)

-- DROP FUNCTION IF EXISTS public.gbt_float4_distance(internal, real, smallint, oid, internal);

CREATE OR REPLACE FUNCTION public.gbt_float4_distance(
	internal,
	real,
	smallint,
	oid,
	internal)
    RETURNS double precision
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbt_float4_distance'
;

ALTER FUNCTION public.gbt_float4_distance(internal, real, smallint, oid, internal)
    OWNER TO mmcam_dev;
