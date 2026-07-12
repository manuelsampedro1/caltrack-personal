# Plan semanal adaptativo

## Problema

Caltrack ya reúne comida, composición, actividad, recuperación y entrenamientos. El hueco principal es que los rangos de calorías y proteína siguen siendo números manuales. Registrar más datos no sirve si la app no ayuda a decidir si mantener el plan o corregirlo.

La solución debe cerrar ese bucle sin fingir precisión médica, sin cambiar objetivos en silencio y sin premiar datos incompletos.

## Casos de uso

- Marcar que el registro de un día está completo.
- Indicar hambre y energía en pocos segundos al cerrar el día.
- Elegir perder, mantener o ganar peso, con un ritmo semanal moderado.
- Ver cuántos días completos y mediciones respaldan la revisión.
- Recibir una recomendación pequeña y explicada una vez hay evidencia suficiente.
- Aplicar o ignorar la propuesta. El usuario conserva el control.

## Opciones técnicas

### Calcular metabolismo desde edad, sexo, altura y actividad

Ventaja: ofrece una cifra desde el primer día.

Problemas: añade datos sensibles, depende de una fórmula poblacional y puede transmitir una precisión que no existe. El NIH Body Weight Planner requiere varios datos y usa un modelo dinámico más complejo que una regla simple.

### Ajustar directamente desde ingesta y cambio de peso

Ventaja: se personaliza con el comportamiento real.

Problemas: una conversión fija de kilos a calorías ignora adaptación, agua y errores de registro. No debe usarse como una predicción exacta.

### Control semanal por pasos pequeños

Ventaja: compara el ritmo real con el objetivo, exige días declarados completos y propone cambios de solo 100 kcal. No necesita estimar un metabolismo ni inventar un gasto.

Esta es la opción recomendada. Si la adherencia al rango actual es baja, la app no cambia el objetivo y recomienda probar el plan actual primero. Si faltan datos, explica exactamente qué falta.

## Diseño

Referencias:

1. El flujo del Caltrack original prioriza captura rápida y lectura inmediata.
2. MacroFactor usa un check-in semanal que propone cambios de objetivos y explica pausas por falta de datos.
3. Apple recomienda jerarquía clara, componentes nativos y revelado progresivo para información secundaria.

La pantalla Hoy mantiene la foto como acción principal. El cierre diario aparece dentro de la tarjeta Hoy, después del resumen nutricional. La revisión semanal aparece después de Hoy y antes de entrenamientos, con:

- estado del plan
- evidencia disponible
- ritmo objetivo y observado
- recomendación en lenguaje directo
- botón explícito para aplicar, cuando proceda
- acceso a una sheet nativa para configurar el objetivo

Paleta y componentes:

- verde para acción o plan estable
- azul para evidencia y configuración
- coral solo para advertencias reales
- SF Symbols `checkmark.circle.fill`, `target`, `chart.line.uptrend.xyaxis`
- tarjetas existentes de 20 puntos y espacios de 14 a 16 puntos
- haptic de éxito al cerrar un día o aplicar una propuesta
- transiciones suaves que respetan Reduce Motion

## Datos

`DailyPlanCheckIn` guarda localmente:

- identificador diario estable
- fecha
- registro nutricional completo
- hambre de 1 a 5
- energía de 1 a 5

La configuración usa `AppStorage`:

- modo `lose`, `maintain` o `gain`
- ritmo semanal objetivo
- peso objetivo opcional

El motor recibe valores simples y devuelve un resultado inmutable. No accede a red, HealthKit o SwiftData.

## Reglas del motor

- Ventana de 14 días.
- Mínimo de 7 días cerrados.
- Mínimo de 3 pesos que cubran al menos 7 días.
- Tendencia calculada con regresión lineal, no solo primer y último peso.
- Al menos 70 por ciento de días cerrados dentro del rango calórico actual antes de proponer cambiarlo.
- Tolerancia de 0,15 kg por semana frente al ritmo objetivo.
- Cambios de solo 100 kcal por revisión.
- Nunca se aplica automáticamente.
- Una recomendación que dejase el rango fuera de los límites actuales de seguridad se bloquea.

## Privacidad y límites

- Todo el cálculo ocurre en el iPhone.
- Los check-ins entran en la copia privada.
- No se envían a xAI al analizar una foto.
- El entrenador solo recibe una síntesis si el usuario formula una pregunta.
- La revisión es una ayuda de comportamiento, no un diagnóstico ni una prescripción.

## Referencias

- [HealthKit en las Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/healthkit)
- [Layout en las Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/layout)
- [NIH Body Weight Planner](https://www.niddk.nih.gov/bwp)
- [Check-ins y coaching de MacroFactor](https://help.macrofactorapp.com/en/articles/247-introduction-to-check-ins-and-coaching-modules)
- [Tuit original de Caltrack](https://x.com/levelsio/status/2075642972243190039)
