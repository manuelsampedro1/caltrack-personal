# Núcleo de super app

## Objetivo

Caltrack debe cubrir el ciclo completo de uso personal: capturar comida, corregirla, entender el día, revisar tendencias, importar cuerpo y entrenamiento, hacer preguntas sobre el progreso, proteger los datos y recuperar una copia. Debe seguir funcionando sin VPS, cuenta propia ni backend.

## Auditoría de la versión actual

### Ya resuelto

- Foto de comida con Grok y macros editables.
- Persistencia local con SwiftData.
- Peso, grasa, cintura y entrenamientos desde Apple Salud.
- Detalle de fuerza desde Hevy Pro.
- Resumen diario, gráfico semanal y objetivos configurables.
- Claves privadas en Keychain.

### Carencias que impiden considerarla completa

- No existe navegación específica para historial, progreso y entrenador.
- El registro manual solo aparece como salida de emergencia cuando falla Grok.
- El análisis diario es una regla breve y no permite preguntas como en la referencia.
- Solo se conserva la última medición de Salud, por lo que faltan tendencias históricas iniciales.
- La app nativa no puede exportar ni restaurar una copia completa.
- No existen recordatorios locales configurables.
- No hay historial persistente de conversaciones con el entrenador.

## Casos de uso

1. Fotografiar o introducir manualmente una comida en menos de 20 segundos.
2. Ver calorías, proteína y macros del día sin interpretar un dashboard complejo.
3. Revisar 14 días de nutrición, evolución corporal y volumen de entrenamiento.
4. Preguntar a Grok qué mejorar usando únicamente el resumen de datos que el usuario decide enviar.
5. Recuperar toda la información tras cambiar de iPhone mediante un JSON privado.
6. Recibir un recordatorio diario opcional sin servidor ni seguimiento.

## Arquitectura

### Navegación

Un `TabView` nativo separa tres contextos reales:

- Hoy: captura y decisiones inmediatas.
- Progreso: tendencias e historial.
- Entrenador: análisis local y preguntas a Grok.

Los ajustes siguen en una sheet porque son configuración, no una actividad principal.

### Progreso

Swift Charts presenta calorías y proteína por día, peso, grasa, cintura y carga de entrenamiento. HealthKit consulta muestras recientes y SwiftData conserva un historial diario para que las tendencias existan desde la primera sincronización.

### Entrenador

Las observaciones básicas se calculan localmente. Una pregunta voluntaria genera un resumen limitado de 30 días y lo envía a xAI con `store: false`. No se envían fotos ni identificadores de HealthKit. Las respuestas quedan guardadas solo en SwiftData.

### Copia privada

Un `FileDocument` JSON contiene comidas, fotos, medidas, entrenamientos y conversación. Exportación y restauración usan los selectores del sistema. Las claves de Keychain nunca forman parte de la copia.

### Recordatorios

UserNotifications programa un recordatorio diario local. Está desactivado por defecto y requiere una acción explícita.

## Pase de diseño

### Referencias

1. La referencia de Pieter Levels: captura inmediata, objetivos visibles, historial duradero y preguntas profundas.
2. Apple Health y Fitness: jerarquía de métricas, color funcional, gráficos sobrios y permisos contextuales.
3. La pantalla nativa actual: carbón, verde, azul y coral, conservando su carácter pero reduciendo la acumulación de tarjetas.

### Sistema visual

- Paleta: carbón `#0B0D10`, tarjeta `#16191F`, elevada `#1F232B`, verde `#73E18A`, azul `#6694FA`, coral `#FA6E6B`.
- Tipografía: San Francisco, títulos fuertes, cifras monoespaciadas en métricas.
- Espaciado: base de 8 puntos, margen de 16, bloques de 12 y 16.
- Iconos: SF Symbols, sin assets decorativos nuevos.
- Estados: vacío, cargando, preparado, error y sin clave.
- Movimiento: transiciones cortas, haptics en guardado y respuesta, respeto a Reduce Motion.

## Seguridad y límites

- No se generan consejos médicos, diagnósticos o déficits agresivos.
- Las estimaciones de foto siguen requiriendo confirmación.
- El entrenador debe describir incertidumbre y basarse en tendencias, no en un día aislado.
- La copia puede contener fotos y datos de salud, por lo que se etiqueta como privada.
- Ninguna clave se incluye en Git, backup o textos enviados al entrenador.

## Referencias

- [Swift Charts](https://developer.apple.com/documentation/Charts)
- [Lectura de HealthKit](https://developer.apple.com/documentation/healthkit/reading-data-from-healthkit)
- [FileDocument](https://developer.apple.com/documentation/SwiftUI/FileDocument)
- [Notificaciones locales](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)
- [Salidas estructuradas de xAI](https://docs.x.ai/developers/model-capabilities/text/structured-outputs)
