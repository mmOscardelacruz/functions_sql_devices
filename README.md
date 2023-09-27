# Actualización de `vehicle` y `vehicle_device`

## Objetivo

Actualizar las funciones para obtener los seriales de cada dispositivo asociado.

## Funciones a actualizar:

- `added_to_ftapi_fn`
- `advanced_report_geotab_select_fn`
- `advanced_report_select_fn`
- `check_user_alarm_permission_json`
- `dashboard_resume` 
  - *Nota:* Apuntar también a tablas particionadas.
- `device_id_select_fn`
- `download_video_from_geotab_alarm_task_fn` 
  - *Detalle:* Solo obtiene las de Geotab. Apuntar a `vehicle_device` para dispositivos GO y serial del MDVR. 
  - *Objetivo:* Mantener la infraestructura.
- `download_video_from_streamax_alarm_task_fn` 
  - *Detalle:* Similar al anterior, pero para Streamax.
- `driver_for_identification_task`
  - *Objetivo:* Mantener estructura de la función.
- `driver_vehicle_select_fn`
  - *Detalle:* El JSON debe ser igual, cambiar fuente a `vehicle_device` para MDVRs.
- `drivers_top_5_fn`
  - *Detalle:* Cambiar para obtener el serial del MDVR de la tabla nueva.
- `drivers_zoom`
  - *Detalle:* Similar al anterior.
- `entry_exit_rules_devices_fn`
  - *Detalle:* Cambiar `geotab_go_id` a `vehicle_device` para dispositivos GO.
- `evidence_count_limit_fn`
  - *Detalle:* Cambiar origen de MDVR a `vehicle_device`.
- `geotab_alarm_by_user_select_excel_report_fn`
  - *Detalle:* Cambiar origen de datos de MDVR a `vehicle_device`.
- `geotab_alarm_by_user_select_fn`
  - *Detalle:* Similar al anterior.

### Notas adicionales:

1. `driver_insert_fn` existe tres veces en la DB. Determinar la versión correcta.
2. `drivers_top_5_fn` - Cambiar de las tablas originales a las tablas particionadas de alarmas.
3. `drivers_zoom` - Similar al anterior.

## Nueva estructura para seriales

Los seriales, ahora bajo el nombre **devices**, poseerán la siguiente estructura:

```json
[
    {
        "deviceId": "",
        "type": "mdvr | lytx | streamax",
        "model": "",
        "serial": "",
        "imei": "",
        "sim": "",
        "camera": [
            {
                "chl": "",
                "name": "",
                "type": ""
            }
        ]
    }
]

