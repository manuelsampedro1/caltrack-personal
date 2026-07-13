# Progreso de calidad nutricional y fibra

## Estado: validación terminada, publicación en curso

## Decisiones

- Fibra opcional para conservar la diferencia entre desconocido y cero.
- Referencia inicial de 25 g editable.
- Suma local y ninguna llamada adicional a Grok.
- Cobertura visible en lugar de falsa precisión.
- Sin impacto en el score cuando faltan datos.

## Evidencia completada

- Build de app y widget en simulador.
- 33 pruebas unitarias y 14 pruebas UI sin fallos, 47 en total.
- Pruebas UI de foto, código, edición, alta, borrado, persistencia, gráfica de fibra y widgets.
- Capturas revisadas de Hoy, Progreso, producto, análisis de foto, componentes y widgets.
- Migración v1.9 a v1.10 con 42 comidas, 9 medidas, 4 entrenamientos y 14 registros de cada serie diaria intactos.
- Las 42 comidas legacy quedan con fibra desconocida y la base añade `ZFIBER` sin inventar ceros.
- Build Release 1.10 (11) firmado y verificado con HealthKit y App Group en la app, y App Group en el widget.

## Evidencia pendiente

- Publicar el SHA final y verificar Pages.
