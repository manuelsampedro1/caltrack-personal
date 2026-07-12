# Pulido nativo y conexiones

## Objetivo

Caltrack debe dejar claro en pocos segundos qué puede hacer, qué servicios están preparados y cuál es la acción principal. La versión web sigue siendo una alternativa local, pero Apple Salud solo puede funcionar en la app nativa del iPhone.

## Referencias de diseño

1. El Caltrack de Pieter Levels prioriza utilidad directa: registrar una comida, ver déficit y proteína, conservar historial y poder hacer preguntas sobre el progreso.
2. Las guías de Apple Salud recomiendan pedir permisos dentro de un contexto claro, explicar para qué se usan y mantener el control en manos del usuario.
3. La app actual aporta la base visual oscura y los datos necesarios, pero tiene demasiadas tarjetas con el mismo peso y esconde las conexiones debajo del primer scroll.

## Dirección visual

- Paleta: fondo carbón `#0B0D10`, superficie `#16191F`, superficie elevada `#1F232B`, verde `#73E18A`, azul `#6694FA`, coral `#FA6E6B` y naranja solo para Strava.
- Tipografía: San Francisco del sistema, títulos compactos con peso fuerte y cifras monoespaciadas cuando mejoren la lectura.
- Espaciado: base de 8 puntos, margen lateral de 16, separación de 12 entre controles y de 16 entre bloques.
- Iconos: SF Symbols, cámara para registrar, corazón para Salud, pesa para Hevy, llama para calorías y escudo para privacidad.
- Estados: sin configurar, preparando, preparado, sincronizando y error recuperable.
- Interacción: haptic ligero al conectar, guardar o sincronizar. Transiciones cortas y compatibles con Reduce Motion.

## Arquitectura recomendada

### Apple Salud

HealthKit es la bandeja local para peso, grasa, cintura y resúmenes de entrenamientos procedentes de Hevy, Strava u otras apps. La conexión debe estar visible al entrar. Apple no permite a una app saber si se denegó la lectura de un tipo concreto, por lo que el estado correcto es `Salud preparada`, no una afirmación absoluta de acceso.

### Hevy

La API oficial enriquece los resúmenes con rutina, ejercicios, series, repeticiones, cargas, RPE y volumen. La clave debe validarse antes de guardarse y mantenerse únicamente en Keychain. La cuenta actual respondió correctamente y devolvió 10 entrenamientos recientes.

### IA nutricional

Una sola API es suficiente. xAI Grok recibe la foto y devuelve un JSON estricto editable con alimentos, porciones, calorías, proteína, carbohidratos, grasa, confianza y supuestos. El análisis diario básico sigue siendo local. Añadir OpenAI duplicaría claves, coste y privacidad sin aportar valor al flujo principal.

## Riesgos y mitigaciones

- Una foto no mide cantidades exactas. La confirmación humana sigue siendo obligatoria.
- La clave compartida en un chat debe considerarse expuesta. Se usa solo para validación y debe regenerarse antes del uso habitual.
- HealthKit no funciona desde Safari o una PWA. La web debe explicarlo sin presentar un botón imposible.
- No se debe incrustar ninguna clave personal en el código, `Info.plist` o binario.

## Referencias

- [Tuit original](https://x.com/levelsio/status/2075642972243190039)
- [HealthKit](https://developer.apple.com/documentation/healthkit)
- [Diseño para HealthKit](https://developer.apple.com/design/human-interface-guidelines/healthkit/)
- [Imágenes con xAI](https://docs.x.ai/developers/model-capabilities/images/understanding)
- [Salidas estructuradas de xAI](https://docs.x.ai/developers/model-capabilities/text/structured-outputs)
- [API oficial de Hevy](https://api.hevyapp.com/docs/)
