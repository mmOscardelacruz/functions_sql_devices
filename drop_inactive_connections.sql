-- FUNCTION: public.drop_inactive_connections()

-- DROP FUNCTION IF EXISTS public.drop_inactive_connections();

CREATE OR REPLACE FUNCTION public.drop_inactive_connections(
	)
    RETURNS TABLE(pg_terminate_backend boolean) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

DECLARE
	vQueryForInactiveConnections	TEXT;

BEGIN
	RETURN query

	WITH inactive_connections AS (
    SELECT
        pid,
        rank() over (partition by client_addr order by backend_start ASC) as rank
    FROM 
        pg_stat_activity
    WHERE
        -- Exclude the thread owned connection (ie no auto-kill)
        pid <> pg_backend_pid( )
    AND
        -- Exclude known applications connections
        application_name !~ '(?:psql)|(?:pgAdmin.+)' 
    --AND
        -- Include connections using the same thread username connection
        --usename = current_user 
    AND
        -- Include inactive connections only
        state in ('idle', 'idle in transaction', 'idle in transaction (aborted)', 'disabled') 
    AND
        -- Include old connections (found with the state_change field)
        current_timestamp - state_change > interval '5 minutes' 
)
 	SELECT
 		pg_terminate_backend(pid)
 	FROM
 		inactive_connections 
 	WHERE
 		rank > 1;

END
$BODY$;

ALTER FUNCTION public.drop_inactive_connections()
    OWNER TO mmcam_dev;
