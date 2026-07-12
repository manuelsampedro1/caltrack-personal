# Implementación de widgets de inicio y bloqueo

## Fase 1: Snapshot compartido

- [x] Añadir App Group a la app y a la extensión.
- [x] Crear un modelo mínimo, Codable y sin dependencias de SwiftData.
- [x] Reiniciar datos diarios caducados sin perder objetivos.
- [x] Mover la ruta de App Intents al almacenamiento compartido.
- [x] Cubrir codificación, caducidad y consumo único con tests.

### Criterio

La extensión puede leer el estado de hoy y ejecutar una ruta sin acceder a la base, HealthKit o Keychain.

## Fase 2: Extensión WidgetKit

- [x] Crear el target y embebido de `CaltrackWidgets.appex`.
- [x] Implementar tamaños pequeño y mediano.
- [x] Implementar familias de bloqueo inline, circular y rectangular.
- [x] Añadir placeholder y estado vacío veraces.
- [x] Marcar métricas privadas y respetar modos de renderizado.

### Criterio

Todas las familias compilan desde una sola vista adaptativa y ninguna muestra datos de un día anterior.

## Fase 3: Sincronización y acciones

- [x] Generar el snapshot desde los datos ya calculados en Hoy.
- [x] Recargar WidgetKit solo cuando cambie el snapshot.
- [x] Conectar foto, código y check-in con los App Intents existentes.
- [x] Mantener Siri, Spotlight y botón Acción sin regresiones.

### Criterio

Guardar, editar, borrar o cerrar un día cambia el snapshot, y cada acción abre directamente su destino.

## Fase 4: Diseño, pruebas y release

- [x] Crear una galería DEBUG que use las mismas vistas del widget.
- [x] Añadir recorrido UI y capturas de tamaños clave.
- [x] Inspeccionar visualmente estado normal, vacío y privado.
- [x] Validar que el `.appex` queda embebido y con entitlements correctos.
- [x] Ejecutar suite limpia, actualizar documentación y publicar v1.8.

### Criterio

El proyecto genera de forma determinista, la app y extensión compilan sin warnings, las capturas son legibles y Pages publica el SHA final.
