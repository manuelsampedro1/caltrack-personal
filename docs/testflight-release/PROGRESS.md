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
- Build 13 preparada con manifiesto de privacidad en app y widget.
- 36 pruebas unitarias pasan, incluida la verificación del manifiesto y export compliance.
- Suite completa build 13: 36 pruebas unitarias y 14 UI, 50 sin fallos.
- Archive y export build 13 correctos desde `1e082a8381c254e47ef2b498502d30aa1b98d6c3`.
- IPA build 13 con Apple Distribution, HealthKit, App Group, privacidad en ambos bundles y cero warnings.
- `ITSAppUsesNonExemptEncryption=false` comprobado dentro del IPA.
- SHA-256 definitivo: `36c63f8a3f7eeb748e1c951ef35950ce57a27980d462f761610d8b990733f1ed`.
- La build 12 anterior queda reemplazada por la 13 y no debe subirse.

## Bloqueos externos actuales

- La ficha de Caltrack no existe y la credencial activa no tiene permiso para crear apps.
- Una clave secundaria debe revocarse porque apareció en una traza de diagnóstico.
- El iPhone de Manolo sigue `unavailable`, así que tampoco se puede instalar directamente desde Xcode.

## Siguiente acción segura

- Con una cuenta Admin o App Manager, crear una app iOS llamada `Caltrack`, idioma `Español (España)`, bundle ID `com.manuelsampedro.caltrack` y SKU `caltrack-personal-ios`.
- Después ejecutar `ios/scripts/release_testflight.sh 13 upload` con la credencial activa no expuesta.
