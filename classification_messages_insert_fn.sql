-- FUNCTION: public.classification_messages_insert_fn(character varying, character varying, json)

-- DROP FUNCTION IF EXISTS public.classification_messages_insert_fn(character varying, character varying, json);

CREATE OR REPLACE FUNCTION public.classification_messages_insert_fn(
	vtoken character varying,
	vmessage character varying,
	vgroups json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    vUserId     BIGINT;
    vClassId    BIGINT;
    vResult 	tpResponse;
    /*LANGUAGE*/
	vUserLng	INT;
BEGIN
    --VERIFICAR QUE EL TOKEN SEA VÁLIDO
    vUserId := checkValidToken(vtoken);
        
    --OBTENER EL IDIOMA DEL USUARIO
    vUserLng := (SELECT language_id FROM userconfig WHERE IdUser = vUserId);
    
    -- Validar primero que no se repita el mensaje a insertar
    IF EXISTS (SELECT * FROM public.classification_messages WHERE UPPER(classification_message) = UPPER(vmessage)) THEN
        vResult.code := 400;
        vResult.status := FALSE;
        --vResult.message := message_select_fn(8, 5, vUserLng, 2, '{}'::VARCHAR[]);
        vResult.message := 'Ya existe un mensaje con el mismo contenido';
        RETURN TO_JSON(vResult);
    END IF;
    
    -- Insertar en tabla de mensajes
    INSERT INTO public.classification_messages(classification_message, editable) 
    VALUES (vmessage, TRUE) RETURNING id_classification_message INTO vClassId;
    
    -- Insertar en tabla de grupos
    INSERT INTO public.classification_groups(id_classification_message, id_group)
    SELECT vClassId, REPLACE(dt::TEXT, '"', '')::INT
    FROM JSON_ARRAY_ELEMENTS(vgroups::JSON) AS dt;
    
    -- Definir vResult
    vResult.code := 200; vResult.status := TRUE; 
    --vResult.message := message_select_fn(8, 1, vUserLng, 2, '{}'::VARCHAR[]);
    vResult.message := 'Mensaje creado correctamente';
        
    -- Obtener datos para el vResult
    vResult.data := (SELECT ROW_TO_JSON(dt) FROM
    (
        SELECT id_classification_message AS "messageId", classification_message AS "classificationMessage"
        FROM public.classification_messages
        WHERE id_classification_message = vClassId
    ) AS dt);
        
    RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.classification_messages_insert_fn(character varying, character varying, json)
    OWNER TO mmcam_dev;
