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

- [ ] Crear ficha de Caltrack con nombre, idioma, bundle ID y SKU.
- [ ] Validar y subir el IPA.
- [ ] Esperar procesamiento de Apple.
- [ ] Crear o reutilizar grupo interno y añadir la build.

## Fase 4: Evidencia

- [ ] Registrar app ID, build, delivery ID, checksum y estado final.
- [ ] Publicar el SHA de documentación.
