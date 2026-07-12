# Progreso de recuperación

## Estado: v1.6 publicada y validada

## Decisiones

- Sueño, frecuencia cardiaca en reposo y HRV SDNN, solo lectura.
- Comparación contra tendencia personal, sin score de disposición.
- Sueño atribuido al día de despertar.
- Unión de intervalos y elección de una sola fuente por noche.
- Caché local y backup compatible para conservar gráficos sin depender de una consulta inmediata.

## Evidencia inicial

- Apple documenta fases solapadas con tiempo en cama, por lo que no se puede sumar todas las categorías.
- `heartRateVariabilitySDNN` usa unidades de tiempo y Apple Watch registra muestras automáticamente cuando están disponibles.
- Las consultas estadísticas permiten medias de cantidades discretas por intervalos diarios.
- El cliente ya tiene HealthKit, SwiftData, Charts y un flujo de permiso en contexto. No hace falta dependencia ni backend.

## Evidencia de implementación

- Suite completa: 34 de 34 tests superados, 24 unitarios y 10 de interfaz.
- La prueba de interfaz abre Progreso con datos de recuperación y verifica tarjeta, métricas, selector y gráfica.
- Migración real probada instalando v1.6 sobre v1.5: se conservaron 42 comidas, 6 mediciones, 14 días de actividad y 4 entrenamientos; se creó la nueva tabla de recuperación sin borrar datos.
- Copia antigua sin campo de recuperación restaurada correctamente y copia nueva verificada en ida y vuelta.
- Proyecto regenerado dos veces con hashes idénticos.
- Versión publicada desde el commit `44e46e7`; el workflow de Pages `29209694714` terminó correctamente.
- Pendiente fuera del simulador: permiso y contraste con datos reales de Salud en un iPhone firmado.
