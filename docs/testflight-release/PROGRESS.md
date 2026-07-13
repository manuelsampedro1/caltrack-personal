# Progreso de distribución por TestFlight

## Estado: build 13 disponible en TestFlight interno

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
- Ficha creada en App Store Connect con Apple ID `6790503627`, bundle `com.manuelsampedro.caltrack`, español de España, SKU `caltrack-personal-ios` y acceso completo.
- La primera validación remota de la build 13 detectó el canal alfa del icono antes de subir el binario.
- Icono aplanado sobre su fondo original, sin cambiar la composición visual, y preflight añadido al script de release.
- Suite posterior al arreglo: 36 pruebas unitarias y 14 UI, 50 sin fallos.
- Metadatos ASO, privacidad, soporte, edad, categoría, revisión y TestFlight preparados de forma reproducible.
- Páginas públicas de privacidad y soporte desplegadas en GitHub Pages y verificadas con HTTP 200.
- Privacidad publicada en App Store Connect con foto, contenido, Salud y fitness para funcionalidad, vinculados y sin tracking.
- Declaración de dispositivo médico regulado completada como no aplicable.
- Release 1.11 (13) archivada, validada y subida desde `d94f3cff2af1331b046aa69b9519190a20982f61`.
- Delivery y build ID: `d1887bc9-f4f6-4b98-bc9a-a70445886c58`.
- SHA-256 del IPA subido: `13c47af13e2d769bbdb2ecd79e9b0bce86471ad6166d91c276231fddfba26dd4`.
- Apple procesó la build como `VALID`, sin cifrado no exento y con estado interno `IN_BETA_TESTING`.
- Grupo interno `Caltrack Internal` creado con acceso a todas las builds, un tester y la build 13 disponible.
- Nueve capturas reales de 1242 por 2688 píxeles subidas y verificadas en el orden versionado.
- La build 13 está vinculada a la versión 1.11 de App Store, que permanece en `PREPARE_FOR_SUBMISSION` y lanzamiento manual.
- Precio configurado como gratis con España como territorio base.
- Disponibilidad preparada en los 175 países y regiones actuales, con alta automática en territorios nuevos.
- Clasificación por edad actualizada: sin redes sociales, contenido público, publicidad ni mensajería entre usuarios; Salud y bienestar permanece activo.
- Declaración de accesibilidad de iPhone preparada en borrador con interfaz oscura. Apple no permite publicarla hasta que la app esté disponible en App Store.

## Pendiente fuera de la release

- Una clave secundaria debe revocarse porque apareció en una traza de diagnóstico.
- El iPhone de Manolo sigue `unavailable`, así que tampoco se puede instalar directamente desde Xcode.

## Siguiente acción segura

- Aceptar la invitación interna o abrir TestFlight con `manuel0507@gmail.com` e instalar la build 13.
- Probar una comida real, Salud y sincronización de Hevy en el iPhone antes de plantear una revisión pública.
