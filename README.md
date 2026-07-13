# 🥩 Caltrack

Caltrack es una web móvil instalable para registrar calorías, proteína, composición corporal y fuerza. Está inspirada por el [Caltrack de Pieter Levels](https://x.com/levelsio/status/2075642972243190039), pero no necesita VPS, cuenta, servidor ni suscripción.

El repositorio incluye también una app iOS nativa que se acerca todavía más al flujo original: foto de la comida, estimación editable con Grok Vision, escáner de productos envasados, lectura autorizada de composición y recuperación desde Apple Salud, y entrenamientos de Hevy o Strava.

## Usarla en iPhone

1. Abre la web publicada en Safari.
2. Completa tus rangos diarios. Peso y mantenimiento son opcionales.
3. Pulsa `Instalar` o usa `Compartir > Añadir a pantalla de inicio`.
4. Ábrela desde el icono de Caltrack como cualquier otra app.

Después de la primera visita funciona incluso sin conexión.

## Privacidad

Comidas, peso, entrenamientos y fotos se guardan en el almacenamiento privado del navegador del dispositivo. No se envían a GitHub ni a ningún servidor.

Esto implica que Safari en el iPhone y el navegador del Mac tienen historiales separados. Para conservar o mover el historial:

1. Abre ajustes.
2. Pulsa `Descargar copia`.
3. Guarda el JSON en iCloud Drive.
4. Usa `Restaurar copia` en el nuevo dispositivo.

La exportación CSV contiene las comidas y sirve para análisis o una hoja de cálculo. La copia JSON incluye el perfil, comidas, composición corporal, fuerza, entrenamientos y fotos.

## Registro rápido

Ejemplos:

```text
comida 200 g pollo
2 huevos
yogur 240 kcal 42 g proteína
lasaña casera 420 kcal 24 g proteína
```

Caltrack reconoce alimentos frecuentes en español e inglés. Si estima valores, muestra la cantidad asumida. Si no conoce un alimento, exige calorías y proteína explícitas en lugar de inventarlas.

## Funciones

- calorías contra objetivo y mantenimiento
- rangos diarios de calorías, proteína y fibra
- gráficos de siete días
- historial diario detallado
- tendencia de grasa corporal, peso y cintura
- seguimiento de cinco marcas de fuerza
- objetivo semanal de entrenamientos
- fotos de comidas
- análisis de adherencia de 14 días
- preguntas sobre progreso
- CSV y copia privada completa
- modo offline
- instalación en la pantalla de inicio

## Desarrollo local

No hay dependencias ni build:

```bash
python3 -m http.server 8765 --directory caltrack/static
```

Abre `http://127.0.0.1:8765`.

La publicación usa GitHub Pages mediante [pages.yml](.github/workflows/pages.yml). Cada push a `main` publica el contenido de `caltrack/static`.

## App iOS con Grok y Salud

El proyecto nativo está en `ios/Caltrack.xcodeproj` y requiere iOS 17 o posterior.

1. Abre el proyecto en Xcode y selecciona tu iPhone.
2. Comprueba que la cuenta de Apple Developer esté activa en `Xcode > Settings > Accounts`.
3. Ejecuta Caltrack y acepta únicamente los datos de Salud que quieras compartir.
4. En la primera tarjeta, toca `Salud` para mostrar el permiso de Apple.
5. En Ajustes de Caltrack, valida y guarda una clave de xAI. Se conserva en Keychain y nunca se añade a Git.
6. Pulsa `Fotografiar comida`, corrige ingredientes, porciones o macros y guarda el resultado.

La pantalla inicial muestra el estado de Salud, Hevy y Grok sin hacer scroll. La PWA no muestra una conexión falsa: Safari no puede acceder a HealthKit.

### Áreas de la app

- `Hoy`: foto, fototeca, código de barras, entrada manual, edición, objetivos, cierre del día, balance estimado, entrenamientos y seis comidas frecuentes para repetir con un toque.
- `Progreso`: gráficos de 14 días, composición corporal, check-ins manuales con foto privada opcional, gasto, sueño, frecuencia cardiaca en reposo, HRV, búsqueda del historial y carga de entrenamiento.
- `Entrenador`: análisis local sin coste y preguntas voluntarias a Grok usando un resumen privado de 30 días, incluido el promedio agregado de hambre y energía de los días cerrados.
- `Ajustes`: claves validadas, escritura nutricional opcional en Salud, objetivos, recordatorio local, App Shortcuts y copia o restauración JSON con el plan adaptativo.

La primera apertura incluye una introducción breve que se puede omitir. No solicita Salud, notificaciones ni claves automáticamente.

### Revisión precisa de una foto

Grok propone el nombre del plato, confianza, supuestos y un desglose por componentes. Cada componente conserva nombre, porción, calorías, proteína, carbohidratos, grasa y fibra. Se puede corregir, añadir o borrar antes de guardar, y Caltrack recalcula el total de forma local e inmediata.

El desglose queda unido a la comida y vuelve a aparecer al editarla desde Hoy o Progreso. También se conserva al repetir una comida y en la copia JSON privada. Los registros de versiones anteriores siguen abriendo normalmente, solo aparecen sin desglose.

### Fibra y calidad nutricional

Caltrack usa una referencia inicial editable de 25 g de fibra al día. Hoy muestra el avance junto a proteína y calorías. Progreso añade una gráfica de 14 días y aclara cuántas comidas contienen el dato, para no tratar registros antiguos o etiquetas incompletas como cero.

Grok estima fibra en la misma petición de la foto. Open Food Facts aporta el valor declarado cuando está disponible. La entrada manual permite dejarlo vacío. El entrenador local y las preguntas voluntarias a Grok reciben tanto el total como su cobertura.

### Plan semanal adaptativo

Cada día con comidas se puede cerrar indicando hambre y energía de 1 a 5. Caltrack revisa únicamente los días cerrados y compara la tendencia de peso de los últimos 14 días con el rumbo elegido: perder, mantener o ganar.

La revisión necesita al menos siete días cerrados, tres pesos repartidos durante siete días y un 70% de adherencia al rango actual. Si hay evidencia suficiente, propone como máximo 100 kcal arriba o abajo. Nunca aplica un cambio sin mostrar el rango anterior, el nuevo y pedir confirmación. Tras aceptarlo, espera seis días antes de plantear otro.

El cálculo es local, usa regresión lineal para reducir el ruido y no estima metabolismo mediante edad, sexo o altura. Es una tendencia personal, no una recomendación médica.

### Siri, Spotlight y botón Acción

La app nativa publica cuatro App Shortcuts: `Fotografiar comida`, `Escanear producto`, `Nuevo check-in` y `Abrir progreso`. Se pueden ejecutar desde Siri, Spotlight, la app Atajos o el botón Acción de un iPhone compatible. Cada acción abre directamente su destino y se consume una sola vez, incluso si primero hay que completar la introducción.

En `Ajustes > Atajos y Siri` aparecen las frases sugeridas y el enlace nativo a Atajos. El intent solo guarda temporalmente el nombre de la pantalla elegida. No contiene ni comparte comidas, medidas o datos de Salud.

### Widgets de inicio y pantalla de bloqueo

La app nativa incluye widgets pequeño y mediano para ver calorías, proteína, fibra y cierre del día, además de accesos directos a Foto, Código y Peso. También ofrece formatos inline, circular y rectangular para la pantalla de bloqueo y StandBy.

La app prepara un resumen mínimo en un App Group. La extensión no abre la base completa, no consulta Salud, no usa Keychain y no hace peticiones de red. Los valores nutricionales se marcan como privados para que iOS pueda ocultarlos cuando corresponda. Si el resumen pertenece a ayer, el widget reinicia el consumo y conserva solo los objetivos.

Para añadirlo, mantén pulsada la pantalla de inicio o de bloqueo, entra en edición y busca `Caltrack` en la galería de widgets.

### Check-ins corporales

`Progreso > Check-in` permite registrar peso, grasa corporal y cintura aunque esas métricas no estén en Apple Salud. También admite una foto de progreso opcional elegida con el selector privado de Apple. La imagen se reduce localmente a un máximo de 1600 píxeles, se puede ampliar en el visor y queda relacionada con las métricas de ese día.

Los check-ins manuales se pueden editar o eliminar. Las muestras importadas de Salud permanecen separadas y son de solo lectura. Las fotos no se envían a Grok ni a Open Food Facts y se incluyen en la copia JSON privada.

### Productos con código de barras

`Hoy > Código` abre un lector nativo para EAN, UPC y otros códigos lineales comunes. Caltrack consulta directamente Open Food Facts, muestra los valores por 100 g y recalcula calorías y macros según la cantidad consumida. El resultado siempre se puede editar antes de guardarlo.

No requiere cuenta, clave, SDK ni servidor. Si la cámara no está disponible, se puede introducir el código a mano. Open Food Facts es una base colaborativa, por lo que conviene comparar el resultado con la etiqueta del envase.

### Nutrición en Apple Salud

En `Ajustes > Apple Salud` se puede activar `Guardar nutrición en Salud`. Caltrack solicita ese permiso en contexto y guarda cada comida confirmada con calorías, proteína, carbohidratos, grasa y fibra cuando se conoce. La opción está desactivada por defecto, no lee la dieta creada por otras apps y permite sincronizar el historial solo mediante una acción explícita. Si se rechaza únicamente fibra, los cuatro nutrientes anteriores siguen guardándose.

### Recuperación en Apple Salud

Al conectar Salud, Caltrack puede leer los últimos 30 días de sueño, frecuencia cardiaca en reposo y HRV SDNN. La tarjeta `Progreso > Recuperación` muestra las tres métricas, una gráfica seleccionable de 14 días y una comparación con la media personal reciente.

El sueño se atribuye al día de despertar, une intervalos solapados y elige una sola fuente por noche para no duplicar minutos. No crea un score opaco, no aplica umbrales clínicos y no recomienda entrenar o descansar. Los datos se guardan localmente, forman parte de la copia privada y no se envían a xAI.

### Entrenamientos de Hevy y Strava

- Strava: activa `Ajustes > Gestionar apps y dispositivos > Salud > Enviar a Salud`. Caltrack importará tipo de actividad, duración, distancia, calorías y fuente desde HealthKit.
- Hevy: conecta Hevy con Apple Salud para importar el resumen de cada sesión.
- Hevy Pro: añade la clave de la API oficial en Ajustes de Caltrack para recuperar ejercicios, series, repeticiones, cargas, RPE, volumen y mejores series.

Caltrack detecta sesiones equivalentes de Salud y Hevy para no duplicarlas.

La clave se valida contra Hevy antes de guardarse. La integración se ha comprobado con entrenamientos reales de la cuenta, incluidos `5D - Upper B`, `5D - Lower A` y `5D - Upper A`.

Para regenerar el proyecto después de añadir archivos Swift:

```bash
ruby ios/scripts/generate_project.rb
```

La foto elegida se envía directamente a `api.x.ai` para el análisis. Los datos de Salud no se envían a xAI. Consulta [PRIVACY.md](PRIVACY.md).

No hace falta una clave de OpenAI. Caltrack utiliza una única API de IA, xAI Grok, para visión, salida nutricional estructurada y preguntas voluntarias al entrenador. El cálculo de objetivos, adherencia, tendencias y avisos básicos se ejecuta localmente.

## Límite importante

Caltrack organiza estimaciones, no sustituye consejo médico o nutricional. Un déficit concreto puede ser adecuado para una persona y no para otra. El sistema bloquea déficits superiores a 1.000 kcal y señala tendencias agresivas.

Una foto no permite medir porciones, aceites o ingredientes ocultos con precisión. Grok propone una estimación editable por ingrediente que debe revisarse antes de guardarla.
