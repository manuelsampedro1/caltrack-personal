# Foto, Grok y Salud

## Resumen

Caltrack debe acercarse al producto mostrado por Pieter Levels: fotografiar una comida, pedir a Grok Vision que identifique alimentos y porciones, revisar una estimación editable y añadirla al día. Además, el peso y otras medidas deben venir de Salud cuando el usuario lo autorice.

## Problema

El registro por texto sigue teniendo demasiada fricción. La web actual tampoco puede leer Salud y no debe contener una clave privada de xAI en su JavaScript público.

## Casos de uso

- Fotografiar un plato y obtener nombre, ingredientes, calorías, proteína, carbohidratos, grasa, porciones asumidas y nivel de confianza.
- Corregir el resultado antes de guardarlo.
- Repetir o eliminar comidas recientes.
- Leer desde Salud la última medida de peso, grasa corporal y cintura.
- Seguir usando objetivos, composición corporal y fuerza sin conexión.

## Investigación técnica

### Opciones

1. Mantener solo la PWA. Permite fotos, pero no HealthKit. Una clave de xAI en el navegador tiene peor protección y puede fallar por CORS.
2. Añadir backend serverless. Protege la clave y conserva la web, pero no permite leer Salud y crea una nueva superficie para datos sensibles.
3. Crear un cliente iOS local-first. HealthKit funciona de forma nativa, la clave se guarda en Keychain y las fotos se envían directamente a xAI. No requiere VPS.

### Recomendación

Usar la opción 3 y mantener la PWA como alternativa. La app será SwiftUI para iOS 17+, SwiftData para el historial, HealthKit para medidas, PhotosUI y cámara para captura, y URLSession para xAI. La clave se introduce una vez y se guarda en Keychain. No se incluye en el repositorio ni se envía a un servidor propio.

### xAI

xAI acepta imágenes como URL o data URL en la Responses API. Structured Outputs permite exigir un esquema JSON para evitar interpretar texto libre. La petición usará `store: false`, una imagen JPEG redimensionada y un esquema estricto. El resultado siempre se trata como estimación y requiere confirmación.

### HealthKit

HealthKit solo está disponible para apps con la capability correspondiente. La app pedirá acceso de lectura únicamente a peso, porcentaje de grasa y cintura. La autorización se solicitará desde una acción contextual y el usuario podrá cambiarla después en Salud o Ajustes.

## Datos

- `MealEntry`: fecha, nombre, comida, calorías, proteína, carbohidratos, grasa, foto local opcional, fuente y confianza.
- `BodyMeasurement`: fecha, peso, grasa, cintura y fuente.
- `AppSettings`: rangos diarios y ejercicios objetivo.
- La clave xAI vive solo en Keychain.

## UI y UX

- La cámara es la acción principal de la primera tarjeta.
- El resultado aparece en una sheet con foto, desglose, supuestos y campos editables.
- Un indicador diferencia analizando, estimación lista y error recuperable.
- Salud aparece como una tarjeta compacta con última sincronización y permiso.
- Se mantiene la estética carbón, verde, coral y azul del tuit.
- Haptics ligeros, Reduce Motion y componentes nativos.

## Riesgos

- Una sola foto no determina con precisión ingredientes ocultos ni cantidades. Se muestra confianza y se obliga a confirmar.
- No existe `XAI_API_KEY` en el entorno actual. La integración se puede construir y probar con fixtures, pero una llamada real requiere una clave del usuario.
- El iPhone aparece desconectado. La integración real con Salud no puede verificarse hasta conectarlo y aceptar permisos.
- Las apps HealthKit necesitan firma, textos de uso claros y política de privacidad si se distribuyen.

## Referencias

- [Publicación original](https://x.com/levelsio/status/2075642972243190039)
- [xAI Image Understanding](https://docs.x.ai/developers/model-capabilities/images/understanding)
- [xAI Structured Outputs](https://docs.x.ai/developers/model-capabilities/text/structured-outputs)
- [Apple HealthKit](https://developer.apple.com/documentation/healthkit)
- [Autorización de HealthKit](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
