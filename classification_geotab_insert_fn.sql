-- FUNCTION: public.classification_geotab_insert_fn(character varying, bigint, bigint, boolean, character varying)

-- DROP FUNCTION IF EXISTS public.classification_geotab_insert_fn(character varying, bigint, bigint, boolean, character varying);

CREATE OR REPLACE FUNCTION public.classification_geotab_insert_fn(
	vtoken character varying,
	vidgeotabalarm bigint,
	vidclassificationmessage bigint,
	vcalification boolean DEFAULT NULL::boolean,
	vcomment character varying DEFAULT ''::character varying)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vIdUser				BIGINT;
	vUserLng			INT;
	vResult				tpResponse;
	vDateTime			TIMESTAMPTZ(0);
	vIdClassification	BIGINT;
	vOffsetInt			INTERVAL;
BEGIN
	vIdUser := CheckValidToken(vToken);
	vOffsetInt := (SELECT CASE WHEN uc.issummertime THEN tz.offset + INTERVAL '1H' ELSE tz.offset END 
				   FROM timezone AS tz
				   INNER JOIN userconfig AS uc
				   ON tz.id = uc.idtimezone
				   WHERE uc.iduser = vIdUser LIMIT 1);
	/*VALIDACIONES*/
	--VERIFICAR QUE EL ID DE LA ALARMA DE GEOTAB EXISTA:
	/*IF NOT EXISTS (SELECT * FROM geotabalarm WHERE id_geotabalarm = vIdGeotabAlarm) THEN
		--NOTIFICAR QUE NO EXISTE
		--RAISE EXCEPTION 'La alarma seleccionada no existe'; --IDIOMA
		--RAISE EXCEPTION '%', message_select_fn(1, 1, vUserLng, 8, '{}'::VARCHAR[]);
		vResult.code := 200; vResult.status := TRUE; vResult.message := message_select_fn(1, 1, vUserLng, 10, '{}'::VARCHAR[]); vResult.data := '{}';
		RETURN TO_JSON(vResult);
	END IF;
	--VERIFICAR QUE EL ID DE LA CLASIFICACIÓN DEL MENSAJE EXISTA
	IF NOT EXISTS (SELECT * FROM classification_messages WHERE id_classification_message = vIdClassificationMessage) THEN
		--NOTIFICAR QUE NO EXISTA
		--RAISE EXCEPTION 'La clasificación seleccionada no existe'; --IDIOMA
		--RAISE EXCEPTION '%', message_select_fn(1, 1, vUserLng, 9, '{}'::VARCHAR[]);
		vResult.code := 200; vResult.status := TRUE; vResult.message := message_select_fn(1, 1, vUserLng, 10, '{}'::VARCHAR[]); vResult.data := '{}';
		RETURN TO_JSON(vResult);
	END IF;*/
	vDateTime := NOW();
	--INSERTAR EN LA CLASIFICACIÓN
	INSERT INTO classification (id_geotabalarm, id_classification_message, id_user, comment, classification_date)
	VALUES (vIdGeotabAlarm, vIdClassificationMessage, vIdUser, vComment, vDateTime) RETURNING id_classification INTO vIdClassification;
	--GUARDAR LA CALIFICACIÓN EN CASO DE NO SER NULA
	IF (vCalification IS NOT NULL) THEN
		INSERT INTO historical_geotab_alarm_classification (id_geotabalarm, id_user, calification, date_time)
		VALUES (vIdGeotabAlarm, vIdUser, vCalification, vDateTime);
	END IF;
	--REGRESAR LA INFORMACIÓN
	vResult.code := 200; vResult.status := TRUE; vResult.message := '';
	vResult.data := COALESCE((SELECT ROW_TO_JSON(dt)
							 FROM
							 (
								 SELECT c.id_classification AS "IdClassificationMessage", c.id_geotabalarm AS "IdNotify",
								 CASE WHEN cmt.classification_message IS NULL THEN cm.classification_message 
								 ELSE cmt.classification_message END AS "classificationMessage",
								 U.Id, u.username, c.comment, (c.classification_date + vOffsetInt)::TIMESTAMPTZ(0),
								 (SELECT calification FROM historical_geotab_alarm_classification 
								  WHERE id_user = vIdUser AND id_geotabalarm = vIdGeotabAlarm
								  ORDER BY date_time DESC LIMIT 1) AS "calification"
								 FROM classification AS c
								 LEFT JOIN classification_messages AS cm
								 ON c.id_classification_message = cm.id_classification_message
								 INNER JOIN "user" AS u
								 ON c.id_user = u.Id
								 LEFT JOIN classification_message_trans AS cmt
								 ON cm.id_classification_message = cmt.id_classification_message AND cmt.language_id = vUserLng
								 WHERE c.id_classification = vIdClassification
							 ) AS dt), '{}'::JSON);
	RETURN TO_JSON(vResult);
END
$BODY$;

ALTER FUNCTION public.classification_geotab_insert_fn(character varying, bigint, bigint, boolean, character varying)
    OWNER TO mmcam_dev;
