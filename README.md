# 🥩 Caltrack

Caltrack es una web móvil instalable para registrar calorías, proteína, composición corporal y fuerza. Está inspirada por el [Caltrack de Pieter Levels](https://x.com/levelsio/status/2075642972243190039), pero no necesita VPS, cuenta, servidor ni suscripción.

El repositorio incluye también una app iOS nativa que se acerca todavía más al flujo original: foto de la comida, estimación editable con Grok Vision y lectura autorizada de peso, grasa corporal y cintura desde Apple Salud.

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
4. En Ajustes de Caltrack, guarda una clave de xAI. Se conserva en Keychain y nunca se añade a Git.
5. Pulsa `Fotografiar comida`, revisa la estimación y confirma los macros.

Para regenerar el proyecto después de añadir archivos Swift:

```bash
ruby ios/scripts/generate_project.rb
```

La foto elegida se envía directamente a `api.x.ai` para el análisis. Los datos de Salud no se envían a xAI. Consulta [PRIVACY.md](PRIVACY.md).

## Límite importante

Caltrack organiza estimaciones, no sustituye consejo médico o nutricional. Un déficit concreto puede ser adecuado para una persona y no para otra. El sistema bloquea déficits superiores a 1.000 kcal y señala tendencias agresivas.

Una foto no permite medir porciones, aceites o ingredientes ocultos con precisión. Grok propone una estimación que debe revisarse antes de guardarla.
