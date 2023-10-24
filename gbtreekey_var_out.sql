-- FUNCTION: public.gbtreekey_var_out(gbtreekey_var)

-- DROP FUNCTION IF EXISTS public.gbtreekey_var_out(gbtreekey_var);

CREATE OR REPLACE FUNCTION public.gbtreekey_var_out(
	gbtreekey_var)
    RETURNS cstring
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbtreekey_out'
;

ALTER FUNCTION public.gbtreekey_var_out(gbtreekey_var)
    OWNER TO mmcam_dev;
