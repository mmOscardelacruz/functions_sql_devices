-- FUNCTION: public.gbtreekey_var_in(cstring)

-- DROP FUNCTION IF EXISTS public.gbtreekey_var_in(cstring);

CREATE OR REPLACE FUNCTION public.gbtreekey_var_in(
	cstring)
    RETURNS gbtreekey_var
    LANGUAGE 'c'
    COST 1
    IMMUTABLE STRICT PARALLEL UNSAFE
AS '$libdir/btree_gist', 'gbtreekey_in'
;

ALTER FUNCTION public.gbtreekey_var_in(cstring)
    OWNER TO mmcam_dev;
