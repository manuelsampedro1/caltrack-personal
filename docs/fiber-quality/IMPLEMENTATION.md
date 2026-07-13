# Implementación de calidad nutricional y fibra

## Fase 1: Modelo compatible

- [x] Añadir fibra opcional a comida y componentes.
- [x] Propagarla por edición y repetición.
- [x] Mantener JSON de componentes anterior compatible.
- [x] Añadir fibra y objetivo opcionales al backup v1.
- [x] Probar base y copia legacy.

### Criterio

Una comida distingue fibra cero de fibra desconocida y la actualización no pierde datos v1.9.

## Fase 2: Captura y sistema

- [x] Pedir fibra en el esquema estructurado de Grok.
- [x] Leer `fiber_100g` de Open Food Facts cuando exista.
- [x] Editar fibra en foto, producto y entrada manual.
- [x] Escribir fibra confirmada en Apple Salud.

### Criterio

Todas las vías de registro conservan fibra sin nueva API y Salud omite el tipo cuando no hay dato.

## Fase 3: Decisión diaria

- [x] Añadir objetivo de fibra editable, 25 g iniciales.
- [x] Mostrar progreso y cobertura en Hoy.
- [x] Añadir fibra a la gráfica de 14 días.
- [x] Incluir fibra y cobertura en entrenador local y contexto de Grok.
- [x] Mostrar fibra en widget mediano cuando exista.

### Criterio

La app responde cuánto se ha registrado, cuánto falta y si el dato está incompleto sin penalizar registros legacy.

## Fase 4: Calidad y publicación

- [x] Crear fixtures completos y parciales.
- [x] Probar cálculo, backup, Open Food Facts, Grok y Salud.
- [x] Inspeccionar Hoy, Progreso y edición en iPhone 16.
- [x] Validar migración v1.9 a v1.10.
- [x] Ejecutar suite, build firmado y auditoría.
- [ ] Actualizar documentación y publicar.

### Criterio

La versión firmada conserva datos, no añade warnings y el SHA publicado tiene evidencia verificable.
