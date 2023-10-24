-- FUNCTION: public.close_idle_connections()

-- DROP FUNCTION IF EXISTS public.close_idle_connections();

CREATE OR REPLACE FUNCTION public.close_idle_connections(
	)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vClosedConnections INT;
BEGIN

	vClosedConnections :=
	(
		SELECT COUNT(*)
		FROM
		(
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
			AND
				-- Include connections to the same database the thread is connected to
				datname = current_database() 
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
			rank > 1 -- Leave one connection for each application connected to the database
		) AS dt
	);
	
	RETURN 'CONEXIONES CERRADAS: ' || vClosedConnections;
END
$BODY$;

ALTER FUNCTION public.close_idle_connections()
    OWNER TO mmcam_dev;
