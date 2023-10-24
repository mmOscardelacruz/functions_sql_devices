-- FUNCTION: public.date_dist(date, date)

-- DROP FUNCTION IF EXISTS public.date_dist(date, date);

CREATE OR REPLACE FUNCTION public.date_dist(
	date,
	date)
    RETURNS integer
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'date_dist'
;

ALTER FUNCTION public.date_dist(date, date)
    OWNER TO mmcam_dev;
