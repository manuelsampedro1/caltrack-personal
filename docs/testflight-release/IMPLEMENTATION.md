# Implementación de distribución por TestFlight

## Fase 1: Preparación reproducible

- [x] Verificar bundle IDs, firma y certificado de distribución.
- [x] Añadir `ExportOptions.plist` para App Store Connect.
- [x] Añadir script con preflight, archive, export, validación y subida opcional.
- [x] Excluir artefactos de release del repositorio.

## Fase 2: Artefacto

- [x] Ejecutar pruebas desde el SHA de release.
- [x] Archivar y exportar IPA.
- [x] Verificar firma, entitlements, versión y checksum.
- [x] Añadir manifiesto de privacidad a app y widget.
- [x] Declarar export compliance exento.
- [x] Regenerar y verificar la build 13.

## Fase 3: App Store Connect

- [x] Crear ficha de Caltrack con nombre, idioma, bundle ID y SKU.
- [x] Preparar nombre, subtítulo, descripción, keywords, privacidad, soporte y notas de revisión.
- [x] Corregir el canal alfa del icono y añadir un preflight para evitar otra entrega inválida.
- [x] Publicar la privacidad y declarar que no es un dispositivo médico regulado.
- [x] Validar y subir el IPA.
- [x] Esperar procesamiento de Apple.
- [x] Crear el grupo interno, añadir el tester y confirmar acceso a la build.
- [x] Subir nueve capturas reales y vincular la build 13 a la versión 1.11.
- [x] Configurar precio gratis y disponibilidad en 175 países y regiones.
- [x] Actualizar las preguntas de redes sociales y mensajería de la clasificación por edad.
- [x] Preparar la declaración conservadora de accesibilidad en estado borrador.

## Fase 4: Evidencia

- [x] Registrar app ID, build, delivery ID, checksum y estado final.
- [x] Publicar el SHA de documentación.
