# Implementación de sincronización de Hevy

## Fase 1: Cliente

- [x] Decodificar `page` y `page_count` de forma opcional.
- [x] Respetar `pageSize` máximo 10.
- [x] Cargar varias páginas con tope seguro.
- [x] Deduplicar por ID.

## Fase 2: Integración

- [x] Hacer una carga inicial de hasta 100 sesiones.
- [x] Mantener actualizaciones posteriores en una página.
- [x] Reiniciar la carga inicial al sustituir o eliminar la clave.
- [x] Mostrar si hay historial anterior no importado.

## Fase 3: Validación

- [x] Probar paginación, deduplicación, límite y compatibilidad.
- [x] Ejecutar suite y build firmado.
- [ ] Publicar y verificar Pages.
