-- FUNCTION: public.cash_dist(money, money)

-- DROP FUNCTION IF EXISTS public.cash_dist(money, money);

CREATE OR REPLACE FUNCTION public.cash_dist(
	money,
	money)
    RETURNS money
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'cash_dist'
;

ALTER FUNCTION public.cash_dist(money, money)
    OWNER TO mmcam_dev;
