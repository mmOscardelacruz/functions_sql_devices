-- FUNCTION: public.gbtreekey4_in(cstring)

-- DROP FUNCTION IF EXISTS public.gbtreekey4_in(cstring);

CREATE OR REPLACE FUNCTION public.gbtreekey4_in(
	cstring)
    RETURNS gbtreekey4
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbtreekey_in'
;

ALTER FUNCTION public.gbtreekey4_in(cstring)
    OWNER TO mmcam_dev;
