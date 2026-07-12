# 🥩 Caltrack

Caltrack es una web móvil instalable para registrar calorías, proteína, composición corporal y fuerza. Está inspirada por el [Caltrack de Pieter Levels](https://x.com/levelsio/status/2075642972243190039), pero no necesita VPS, cuenta, servidor ni suscripción.

El repositorio incluye también una app iOS nativa que se acerca todavía más al flujo original: foto de la comida, estimación editable con Grok Vision, escáner de productos envasados, lectura autorizada de peso, grasa corporal y cintura desde Apple Salud, y entrenamientos de Hevy o Strava.

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
- rangos diarios de calorías y proteína
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
6. Pulsa `Fotografiar comida`, revisa la estimación y confirma los macros.

La pantalla inicial muestra el estado de Salud, Hevy y Grok sin hacer scroll. La PWA no muestra una conexión falsa: Safari no puede acceder a HealthKit.

### Áreas de la app

- `Hoy`: foto, fototeca, código de barras, entrada manual, edición, objetivos, balance estimado, entrenamientos y seis comidas frecuentes para repetir con un toque.
- `Progreso`: gráficos de 14 días, composición corporal, check-ins manuales con foto privada opcional, gasto de Salud, búsqueda del historial de comidas y carga de entrenamiento.
- `Entrenador`: análisis local sin coste y preguntas voluntarias a Grok usando un resumen privado de 30 días.
- `Ajustes`: claves validadas, escritura nutricional opcional en Salud, objetivos, recordatorio local y copia o restauración JSON.

La primera apertura incluye una introducción breve que se puede omitir. No solicita Salud, notificaciones ni claves automáticamente.

### Check-ins corporales

`Progreso > Check-in` permite registrar peso, grasa corporal y cintura aunque esas métricas no estén en Apple Salud. También admite una foto de progreso opcional elegida con el selector privado de Apple. La imagen se reduce localmente a un máximo de 1600 píxeles, se puede ampliar en el visor y queda relacionada con las métricas de ese día.

Los check-ins manuales se pueden editar o eliminar. Las muestras importadas de Salud permanecen separadas y son de solo lectura. Las fotos no se envían a Grok ni a Open Food Facts y se incluyen en la copia JSON privada.

### Productos con código de barras

`Hoy > Código` abre un lector nativo para EAN, UPC y otros códigos lineales comunes. Caltrack consulta directamente Open Food Facts, muestra los valores por 100 g y recalcula calorías y macros según la cantidad consumida. El resultado siempre se puede editar antes de guardarlo.

No requiere cuenta, clave, SDK ni servidor. Si la cámara no está disponible, se puede introducir el código a mano. Open Food Facts es una base colaborativa, por lo que conviene comparar el resultado con la etiqueta del envase.

### Nutrición en Apple Salud

En `Ajustes > Apple Salud` se puede activar `Guardar nutrición en Salud`. Caltrack solicita ese permiso en contexto y guarda cada comida confirmada con calorías, proteína, carbohidratos y grasa. La opción está desactivada por defecto, no lee la dieta creada por otras apps y permite sincronizar el historial solo mediante una acción explícita.

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

Una foto no permite medir porciones, aceites o ingredientes ocultos con precisión. Grok propone una estimación que debe revisarse antes de guardarla.
