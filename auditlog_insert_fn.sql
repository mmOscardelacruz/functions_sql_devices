CREATE OR REPLACE FUNCTION public.auditlog_insert_fn(
	vusername text,
	vsysfunction text,
	voperation text,
	vnotes text)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
	INSERT INTO auditlog(username, sysfunction, datetime, operation, notes)
	VALUES (vUsername, vSysFunction, NOW(), vOperation, vNotes)
	ON CONFLICT ON CONSTRAINT auditlogun DO NOTHING;
END
$BODY$;