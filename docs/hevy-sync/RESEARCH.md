# Investigación de sincronización de Hevy

## Problema observado

Caltrack consultaba `GET /v1/workouts` con `page=1` y `pageSize=10`. La actualización diaria era suficiente, pero una primera instalación podía recuperar solo diez sesiones sin explicarlo.

## Contrato oficial

La documentación OpenAPI de Hevy define:

- `GET /v1/workouts` como lista paginada.
- `page` empieza en 1.
- `pageSize` admite como máximo 10.
- la respuesta contiene `page`, `page_count` y `workouts`.
- la API es para usuarios Hevy Pro y Hevy avisa que el contrato puede cambiar.

Fuente primaria: <https://api.hevyapp.com/docs/>

## Decisión

- Primera sincronización tras conectar o actualizar: hasta 10 páginas, 100 entrenamientos.
- Sincronizaciones posteriores: una página, 10 entrenamientos recientes.
- Deduplicación adicional por identificador antes de persistir.
- Compatibilidad con respuestas anteriores sin metadatos de página.
- Mensaje explícito si existen más páginas que el límite inicial.
- Sin temporizador de fondo, servidor, SDK o credencial adicional.

## Diseño

No se añade una pantalla. Se conserva la tarjeta de entrenamientos y el estado de Ajustes. La primera carga explica el límite solo cuando realmente se alcanza. El patrón mantiene la jerarquía, tipografía, haptics y progresión existentes.
