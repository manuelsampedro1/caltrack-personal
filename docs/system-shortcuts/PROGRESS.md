# Progreso de acceso rápido del sistema

## Estado: completado en simulador

## Decisiones

- Cuatro acciones, dentro del rango de dos a cinco recomendado por Apple.
- Sin parámetros ni datos sensibles en los intents.
- Una ruta pendiente de un solo uso, almacenada localmente.
- Onboarding pospone la ruta en vez de descartarla.
- Descubrimiento en Ajustes mediante `ShortcutsLink`.

## Evidencia inicial

- AppIntents.framework ya forma parte del target, pero no existían intents.
- Xcode confirma que el iPhone real está emparejado pero fuera de línea.
- No hay clave xAI disponible en el entorno actual.
- Apple permite ejecutar App Shortcuts desde Siri, Spotlight, Atajos y el botón Acción.

## Evidencia de implementación

- Build de v1.5, build 6, completado en simulador sin errores.
- `appintentsmetadataprocessor` escribió `Metadata.appintents` con cuatro acciones descubribles.
- El entrenamiento del sistema generó las ocho frases en español y el nombre Caltrack.
- El proveedor es estático, así que no fuerza una actualización dinámica de parámetros al iniciar.
- Dos pruebas unitarias validan consumo único, argumentos, destinos y cantidad de atajos.
- Dos pruebas UI abren directamente código y check-in, y verifican las cuatro acciones en Ajustes.
- La captura visual de Ajustes fue inspeccionada con tamaño de texto grande.
- El fallback de cámara ya no configura opciones de cámara cuando el dispositivo no tiene ese hardware.
- Suite completa: 21 pruebas unitarias y 9 pruebas UI, 30 de 30 correctas.
- La notificación de ruta se entrega en el hilo principal, sin avisos de publicación de SwiftUI.
- Las dos rutas UI se repitieron después de la corrección final y volvieron a pasar.
- El proyecto se regeneró dos veces con hashes idénticos después de estabilizar sus identificadores.

## Bloqueos

- La invocación por voz real necesitará instalar la app firmada en el iPhone.
