-- FUNCTION: public.float8_dist(double precision, double precision)

-- DROP FUNCTION IF EXISTS public.float8_dist(double precision, double precision);

CREATE OR REPLACE FUNCTION public.float8_dist(
	double precision,
	double precision)
    RETURNS double precision
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'float8_dist'
;

ALTER FUNCTION public.float8_dist(double precision, double precision)
    OWNER TO mmcam_dev;
