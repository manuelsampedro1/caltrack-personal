# Progreso de distribución por TestFlight

## Estado: IPA verificado, pendiente de ficha en App Store Connect

## Completado

- Sesión Apple y App Store Connect comprobadas.
- Bundle principal y widget encontrados.
- Certificado Apple Distribution válido.
- Flujo de release reproducible añadido al repositorio.
- 49 pruebas verdes en la misma fuente de aplicación.
- Archive y export correctos desde `70b5d2508e2a316c7473124ed0be6ec427b97d4b`.
- IPA 1.11 (12) firmado con Apple Distribution.
- HealthKit y App Group presentes, `get-task-allow` desactivado y perfiles Store sin dispositivos.
- SHA-256 del IPA: `2485fb78503dc0b94c1b069db479c9a0ccdaf0400299973e1081c154d1bb8283`.
- La validación remota llega a Apple y solo falla al asociar el bundle porque la ficha aún no existe.

## Bloqueos externos actuales

- La ficha de Caltrack no existe y la credencial activa no tiene permiso para crear apps.
- Una clave secundaria debe revocarse porque apareció en una traza de diagnóstico.
- El iPhone de Manolo sigue `unavailable`, así que tampoco se puede instalar directamente desde Xcode.

## Siguiente acción segura

- Con una cuenta Admin o App Manager, crear una app iOS llamada `Caltrack`, idioma `Español (España)`, bundle ID `com.manuelsampedro.caltrack` y SKU `caltrack-personal-ios`.
- Después ejecutar `ios/scripts/release_testflight.sh 12 upload` con la credencial activa no expuesta.
