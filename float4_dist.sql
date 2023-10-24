-- FUNCTION: public.float4_dist(real, real)

-- DROP FUNCTION IF EXISTS public.float4_dist(real, real);

CREATE OR REPLACE FUNCTION public.float4_dist(
	real,
	real)
    RETURNS real
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'float4_dist'
;

ALTER FUNCTION public.float4_dist(real, real)
    OWNER TO mmcam_dev;
