# 🥩 Caltrack

Caltrack es una web móvil instalable para registrar calorías, proteína, peso y entrenamientos. Está inspirada por el [Caltrack de Pieter Levels](https://x.com/levelsio/status/2075642972243190039), pero no necesita VPS, cuenta, servidor ni suscripción.

## Usarla en iPhone

1. Abre la web publicada en Safari.
2. Completa peso, mantenimiento y objetivo.
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

La exportación CSV contiene las comidas y sirve para análisis o una hoja de cálculo. La copia JSON incluye el perfil, comidas, peso, entrenamientos y fotos.

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
- proteína diaria según peso
- gráficos de siete días
- historial diario detallado
- peso y entrenamiento
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

## Límite importante

Caltrack organiza estimaciones, no sustituye consejo médico o nutricional. Un déficit concreto puede ser adecuado para una persona y no para otra. El sistema bloquea déficits superiores a 1.000 kcal y señala tendencias agresivas.

