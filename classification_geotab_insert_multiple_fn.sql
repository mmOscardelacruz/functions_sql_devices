-- FUNCTION: public.classification_geotab_insert_multiple_fn(text, json)

-- DROP FUNCTION IF EXISTS public.classification_geotab_insert_multiple_fn(text, json);

CREATE OR REPLACE FUNCTION public.classification_geotab_insert_multiple_fn(
	vtoken text,
	vdata json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vResponse						tpResponse;
	vIdUser							INTEGER;
	vLanguageId						INTEGER;
	vOffsetInterval					INTERVAL;
	vDateTime						TIMESTAMP(0);
	vClassificationJson				JSON;
	vCount							INTEGER := 0;
	vReturnedClassificationId		BIGINT;
	vClassificationId				BIGINT[];
BEGIN
-- 	INCIALIZAR RESPUESTA.
	IF (JSON_ARRAY_LENGTH(vData) <= 0 OR vData IS NULL) THEN
		RAISE EXCEPTION 'Array could not be empty or null.';
	END IF;
	vResponse.code := 200; vResponse.status := TRUE; vResponse.message := 'Classification_Geotab'; vResponse.data := '[]'::JSON;
	
-- 	VERIFICAR Y OBTENER ID DEL USUARIO.
	vIdUser := checkValidToken(vToken);
	
-- 	OBTENER IDIOMA DEL USUARIO.
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

-- 		INICIAR CONTADOR.
		vCount := (vCount + 1);
		
-- 		INSERTAR CLASIFICACIONES ATENDIDAS.
		INSERT INTO classification (id_geotabalarm, id_classification_message, id_user, comment, classification_date)
		VALUES
		(
		 	CAST(vClassificationJson->>'idAlarm' AS BIGINT),
		 	CAST(vClassificationJson->>'idClassificationMessage' AS BIGINT),
		 	vIdUser,
		 	CAST(vClassificationJson->>'comment' AS TEXT),
		 	vDateTime::TIMESTAMP(0)
		) RETURNING id_classification INTO vReturnedClassificationId;
		
-- 		OBTENER ID DE LAS CLASIFICAIONES PREVIAMENTE ATENDIDAS.
		vClassificationId[vCount] := vReturnedClassificationId;
		RAISE NOTICE 'vClassificationIds: %', vClassificationId;
		
-- 		INSERTAR CALIFICACIONES EN CASO DE EXISTIR.
		IF (vClassificationJson->>'calification' IS NOT NULL) THEN
			INSERT INTO historical_geotab_alarm_classification (id_geotabalarm, id_user, calification, date_time)
			VALUES
			(
				CAST(vClassificationJson->>'idAlarm' AS BIGINT),
				vIdUser,
				CAST(vClassificationJson->>'calification' AS BOOLEAN),
				vDateTime::TIMESTAMP(0)
			);
		END IF;
	END LOOP;
	
	RAISE NOTICE 'vClassificationIds: %', vClassificationId;
	
-- 	EJECUTAR CONSULTA PARA REGRESAR DATOS DE LAS CLASIFICACIONES PREVIAS.
	vResponse.data := COALESCE(
		(
			SELECT ARRAY_TO_JSON(ARRAY_AGG(dt))
			FROM
			(
				SELECT c.id_classification AS "IdClassificationMessage", c.id_geotabalarm AS "IdNotify",
				CASE WHEN cmt.classification_message IS NULL THEN cm.classification_message
				ELSE cmt_classification_message END AS "classificationMessage",
				u.id, u.username, c.comment, (c.classification_date + vOffsetInterval)::TIMESTAMPTZ(0),
				(
					SELECT calification FROM historical_geotab_alarm_classification
					WHERE id_user = vIdUser AND id_geotabalarm = c.id_geotabalarm
					ORDER BY date_time LIMIT 1
				) AS "calification"
				FROM classification AS c
				LEFT JOIN classification_messages AS cm
				ON c.id_classification_message = cm.id_classification_message
				INNER JOIN "user" AS u
				ON c.id_user = u.id
				LEFT JOIN classification_message_trans AS cmt
				ON (cm.id_classification_message = cmt.id_classification_message AND cmt.language_id = vLanguageId)
				WHERE c.id_classification IN (SELECT UNNEST vClassificationId)
			) AS dt
		),'[]'::JSON);
	
	RETURN TO_JSON(vResponse);
END 
$BODY$;

ALTER FUNCTION public.classification_geotab_insert_multiple_fn(text, json)
    OWNER TO mmcam_dev;
