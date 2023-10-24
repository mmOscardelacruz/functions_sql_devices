-- FUNCTION: public.classification_streamax_insert_multiple_fn(text, json)

-- DROP FUNCTION IF EXISTS public.classification_streamax_insert_multiple_fn(text, json);

CREATE OR REPLACE FUNCTION public.classification_streamax_insert_multiple_fn(
	vtoken text,
	vdata json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vIdUser							INTEGER;
	vLanguageId						INTEGER;
	vDateTime						TIMESTAMP(0);
	vResponse						tpResponse;
	vClassificationId				BIGINT[];
	vOffsetInterval					INTERVAL;
	vClassificationJson				JSON;
	vCount							INTEGER := 0;
	vReturnedClassificationId		BIGINT;
	vQueries						TEXT[];
	vQuery							TEXT := '';
BEGIN
-- 	INICIALIZAR RESPUESTA.
	vResponse.code := 200; vResponse.status := TRUE; vResponse.message := 'Classification_Streamax'; vResponse.data := '[]'::JSON;

-- 	VERIFICAR QUE EL TOKEN SEA VALIDO.
	vIdUser := checkValidToken(vToken);
	
-- 	VERIFICAR QUE EL ARREGLO CONTENGA DATOS.
	IF (JSON_ARRAY_LENGTH(vData) <= 0 OR vData IS NULL) THEN
		RAISE EXCEPTION 'Array could not be empty or null.';
	END IF;
	
-- 	OBTENER LENGUAJE DEL USUARIO.
	vLanguageId := (SELECT language_id FROM userconfig WHERE iduser = vIdUser);
	
-- 	OBTENER EL OFFSET DEL USUARIO.
	vOffsetInterval := (
		SELECT CASE WHEN tz.issummertime THEN tz.offset + INTERVAL '1H' ELSE tz.offset END
		FROM timezone AS tz
		INNER JOIN userconfig AS uc
		ON tz.id = uc.idtimezone
		WHERE uc.iduser = vIdUser
	);
	
-- 	OBTENER VALOR DE FECHA ACTUAL PARA GUARDAR EVIDENCIA DE LA OPERACION ACTUAL EN SU FECHA.
	vDateTime := NOW()::TIMESTAMP(0);
	
	RAISE NOTICE 'vIdUser: %', vIdUser;
	RAISE NOTICE 'vLanguageId: %', vLanguageId;
	RAISE NOTICE 'vOffsetInterval: %', vOffsetInterval;
	RAISE NOTICE 'vDataLength: %', JSON_ARRAY_LENGTH(vData);
	
-- 	INSERTAR DATOS HISTORICOS.
	FOR vClassificationJson IN (SELECT JSON_ARRAY_ELEMENTS(vData)) LOOP
	
-- 		INICIALIZAR CONTADOR.
		vCount := (vCount + 1);
		
-- 		INSERTAR CLASIFICAIONES DE LAS ALARMAS ATENDIDAS.
		INSERT INTO classification_streamax (streamax_alarm_id, classification_message_id, user_id, comment, classification_date)
		VALUES 
		(
			CAST(vClassificationJson->>'idAlarm' AS BIGINT),
			CAST(vClassificationJson->>'idClassificationMessage' AS BIGINT),
			vIdUser,
			CAST(vClassificationJson->>'comment' AS TEXT),
			vDateTime::TIMESTAMP(0)
		) RETURNING classification_streamax_id INTO vReturnedClassificationId;
		
-- 		OBTENER IDS DE LAS CLASIFICACIONES ATENDIDAS.
		vClassificationId[vCount] := vReturnedClassificationId;
		
-- 		INSERTAR CALIFICACIONES EN CASO DE EXISTIR.
		IF (vClassificationJson->>'calification' IS NOT NULL) THEN
			INSERT INTO historical_streamax_alarm_classification (id_streamaxalarm, id_user, calification, date_time)
			VALUES
			(
				CAST(vClassificationJson->>'idAlarm' AS BIGINT),
				vIdUser,
				CAST(vClassificationJson->>'calification' AS BOOLEAN),
				vDateTime::TIMESTAMP(0)
			);
		END IF;
		
	END LOOP;
	
	RAISE NOTICE 'vClassificationId: %', vClassificationId;
	
-- 	EJECUTAR CONSULTA PARA REGRESAR DATOS DE LAS CLASIFICACIONES PREVIAS.
	vResponse.data := COALESCE(
		(
			SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
			FROM
			(
				SELECT cs.classification_streamax_id AS "IdClassificationMessage", cs.streamax_alarm_id AS "IdNotify",
				CASE WHEN cmt.classification_message IS NULL THEN cm.classification_message ELSE cmt.classification_message END AS "classificationMessage",
				u.id, u.username, cs.comment, (cs.classification_date + vOffsetInterval)::TIMESTAMPTZ(0),
			    (
					SELECT calification FROM historical_streamax_alarm_classification 
			    	WHERE id_user = vIdUser AND streamax_alarm_id = cs.streamax_alarm_id
			    	ORDER BY date_time DESC LIMIT 1
				) AS "calification"
				FROM classification_streamax AS cs
				LEFT JOIN classification_messages AS cm
				ON cs.classification_message_id = cm.id_classification_message
				INNER JOIN "user" AS u
				ON cs.user_id = u.id
				LEFT JOIN classification_message_trans AS cmt
				ON cm.id_classification_message = cmt.id_classification_message
				AND cmt.language_id = vLanguageId
				AND cmt.language_id = 2
				WHERE cs.classification_streamax_id IN (SELECT UNNEST(vClassificationId))
			) AS dt
		), '[]'::JSON);
		
		RETURN TO_JSON(vResponse);

END 
$BODY$;

ALTER FUNCTION public.classification_streamax_insert_multiple_fn(text, json)
    OWNER TO mmcam_dev;
