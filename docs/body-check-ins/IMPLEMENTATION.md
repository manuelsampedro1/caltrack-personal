# Implementación de check-ins corporales

## Fase 1: Modelo y compatibilidad

- [x] Añadir foto opcional a `BodyMeasurement` con almacenamiento externo.
- [x] Incluir la foto en exportación y restauración sin romper backups anteriores.
- [x] Crear validación y compresión local reutilizable.

### Criterio

Una medición anterior sigue abriendo y una copia antigua se restaura sin foto.

## Fase 2: Registro y edición

- [x] Crear formulario nativo para fecha, peso, grasa y cintura.
- [x] Añadir selección y retirada de foto.
- [x] Permitir editar y eliminar check-ins manuales.
- [x] Mantener las muestras de Salud como solo lectura.

### Criterio

Se puede crear y corregir un check-in sin permisos ni red.

## Fase 3: Progreso visual

- [x] Integrar la acción en la tarjeta de composición.
- [x] Mostrar fotos recientes con fecha y métricas.
- [x] Crear visor a pantalla completa.
- [x] Añadir estados vacío, carga y error.

### Criterio

El usuario encuentra registro, tendencia y fotos dentro de Progreso sin una nueva tab.

## Fase 4: Calidad

- [x] Añadir pruebas de validación, backup y compatibilidad.
- [x] Añadir recorrido UI de creación y edición.
- [x] Probar migración desde la versión 1.3.
- [x] Inspeccionar visualmente en tamaño normal y accesible.
- [x] Actualizar privacidad, decisiones y documentación.
- [x] Ejecutar build y suite completa sin warnings propios.
