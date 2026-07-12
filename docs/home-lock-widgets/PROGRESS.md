# Progreso de widgets de inicio y bloqueo

## Estado: fase 4, validación y publicación

## Decisiones

- Snapshot mínimo en App Group, no base SwiftData compartida.
- Sin backend, red, HealthKit o Keychain dentro de la extensión.
- `systemSmall`, `systemMedium` y tres familias de pantalla de bloqueo.
- Sin widget grande ni Live Activity en esta fase.
- Valores nutricionales marcados como privados.
- Las acciones reutilizan los cuatro App Intents actuales.

## Pase de diseño

- Referencias: HIG de widgets, Fitness y el sistema visual de Caltrack.
- Paleta: carbón, verde y azul. Coral solo para exceso real.
- Tipografía: sistema y números monoespaciados.
- Spacing: 8, 12 y 16 puntos según familia.
- Iconos: SF Symbols, sin assets nuevos ni dependencias.
- Estados: normal, vacío, cerrado, privado y snapshot caducado.
- Interacción: botones nativos del widget, sin gestos ocultos.

## Evidencia actual

- Suite limpia: 30 tests unitarios y 12 recorridos UI, 42 de 42, sin warnings de compilación.
- `CaltrackWidgets.appex` 1.8, build 9, queda embebida y supera la validación de binario de Xcode.
- El build firmado para iPhone pasa con perfiles automáticos: HealthKit y App Group en la app, App Group en el widget.
- El simulador escribe 1.760 kcal, 159 g de proteína, tres comidas y cierre en el App Group real.
- Capturas inspeccionadas de pequeño, vacío, mediano, bloqueo y privacidad.
- La instalación de v1.8 sobre v1.7 conserva 42 comidas, 9 medidas, 14 días de actividad, 14 de recuperación, 4 entrenamientos, 14 cierres y 2 mensajes.
- No hay un iPhone físico conectado a Xcode, así que la instalación real queda como prueba manual.
- Pendiente únicamente la publicación de v1.8.
