-- FUNCTION: public.classification_messages_delete_fn(character varying, json)

-- DROP FUNCTION IF EXISTS public.classification_messages_delete_fn(character varying, json);

CREATE OR REPLACE FUNCTION public.classification_messages_delete_fn(
	vtoken character varying,
	vclassifications json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    vUserId     BIGINT;
    vResult 	tpResponse;
    vClassificationError	BIGINT[];
    /*LANGUAGE*/
	vUserLng	INT;
BEGIN
    --VERIFICAR QUE EL TOKEN SEA VÁLIDO
    vUserId := checkValidToken(vtoken);
        
    --OBTENER EL IDIOMA DEL USUARIO
    vUserLng := (SELECT language_id FROM userconfig WHERE IdUser = vUserId);
    
    -- Definir error por defecto en el resultado
    vResult.code := 400; vResult.status := FALSE;
    
    -- Validar que la clasificación exista
    vClassificationError := (
								SELECT ARRAY_AGG(REPLACE(dt::TEXT, '"', '')::BIGINT)
								FROM JSON_ARRAY_ELEMENTS(vClassifications) AS dt
								LEFT JOIN classification_messages AS cm
								ON REPLACE(dt::TEXT, '"', '')::BIGINT = cm.id_classification_message
								WHERE cm.id_classification_message IS NULL
							);
	IF (ARRAY_LENGTH(COALESCE(vClassificationError, ARRAY[]::BIGINT[]), 1) > 0) THEN
        vResult.message := 'Datos con errores: Algunos elementos no son válidos';
        RETURN TO_JSON(vResult);
	END IF;
    
    -- Validar que la clasificación se pueda editar
    vClassificationError := (
								SELECT ARRAY_AGG(REPLACE(dt::TEXT, '"', '')::BIGINT)
								FROM JSON_ARRAY_ELEMENTS(vClassifications) AS dt
								LEFT JOIN classification_messages AS cm
								ON REPLACE(dt::TEXT, '"', '')::BIGINT = cm.id_classification_message
								WHERE NOT cm.editable
							);
	IF (ARRAY_LENGTH(COALESCE(vClassificationError, ARRAY[]::BIGINT[]), 1) > 0) THEN
        vResult.message := 'Datos con errores: Algunos elementos no pueden ser eliminados';
        RETURN TO_JSON(vResult);
	END IF;
    
    -- Eliminar registros:
    DELETE FROM public.classification_messages
    WHERE id_classification_message IN
    (
        SELECT REPLACE(dt::TEXT, '"', '')::BIGINT AS id
        FROM JSON_ARRAY_ELEMENTS(vClassifications) AS dt
    ) AND editable;
    
    -- Definir vResult
    vResult.code := 200; vResult.status := TRUE;
    vResult.message := 'Clasificación eliminada correctamente';
        
    RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.classification_messages_delete_fn(character varying, json)
    OWNER TO mmcam_dev;
