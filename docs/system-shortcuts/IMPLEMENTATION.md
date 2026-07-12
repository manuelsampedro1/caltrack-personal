# Implementación de acceso rápido del sistema

## Fase 1: Rutas internas

- [x] Crear rutas tipadas y almacenamiento pendiente de un solo uso.
- [x] Enrutar Hoy, Progreso, cámara, código y check-in.
- [x] Conservar la ruta mientras onboarding esté visible.

### Criterio

Una ruta de prueba abre exactamente la superficie solicitada y no se repite.

## Fase 2: App Intents

- [x] Crear cuatro intents sin parámetros.
- [x] Registrar cuatro App Shortcuts con frases en español.
- [x] Abrir la app en primer plano con compatibilidad iOS 17.
- [x] Registrar el proveedor estático sin actualización dinámica innecesaria.

### Criterio

Xcode extrae metadatos válidos para los cuatro intents y atajos.

## Fase 3: Descubrimiento

- [x] Añadir una sección compacta en Ajustes.
- [x] Mostrar nombres, iconos y ejemplos de frase.
- [x] Añadir `ShortcutsLink` nativo.
- [x] Confirmar que no existe copy duplicado en Hevy Pro.

### Criterio

El usuario descubre las acciones sin añadir ruido a Hoy.

## Fase 4: Calidad

- [x] Probar almacenamiento, consumo y contrato de destinos.
- [x] Probar rutas UI de producto y check-in.
- [x] Inspeccionar Ajustes con texto accesible.
- [x] Blindar el fallback de cámara sin hardware.
- [x] Ejecutar build y suite completa sin warnings propios.
- [x] Actualizar privacidad, decisiones y README.
