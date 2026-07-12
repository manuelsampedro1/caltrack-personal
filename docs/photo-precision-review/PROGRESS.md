# Progreso de revisión precisa por foto

## Estado: completado

## Decisiones

- Componentes Codable opcionales dentro de la comida, sin tabla nueva.
- Suma local determinista, sin segunda llamada a Grok.
- Detalle abierto tras foto y progresivo al editar historial.
- Totales finales siguen siendo editables.
- Backup v1 conserva compatibilidad mediante campo opcional.

## Pase de diseño

- Referencias: Caltrack original, MacroFactor y HIG de Apple.
- Paleta: carbón, verde, azul y coral existentes.
- Tipografía: sistema y métricas monoespaciadas.
- Spacing: 8, 12 y 16 puntos.
- Iconos: SF Symbols, sin assets ni dependencias.
- Haptics: añadir, borrar y guardar.
- Estados: detectado, añadido, vacío, corregido, legacy e inválido.

## Evidencia completada

- Editor abierto con tres componentes, total corregido a 790 kcal y 62 g de proteína.
- Estado vacío revisado, con acción para volver a añadir componentes.
- Fixture de análisis fotográfico con cuatro componentes y 86% de confianza, sin consumo de API.
- Pruebas UI específicas de análisis, corrección, persistencia, alta y borrado.
- Migración real en simulador desde v1.8, con 42 comidas, 9 medidas, 4 entrenamientos, 14 cierres, 14 recuperaciones y 14 días de actividad intactos.
- Nueva columna externa `ZCOMPONENTDATA` creada tras la actualización.
- Suite limpia: 32 pruebas unitarias y 14 pruebas UI, 46 en total, sin fallos.
- Build Release firmado para iPhone: app y widget v1.9 build 10, firma válida, HealthKit y App Group comprobados.
- Generador ejecutado dos veces con el mismo SHA-1 de proyecto.
- Auditoría sin warnings del cambio, sin claves en el repositorio y sin guiones Unicode prohibidos.
- Commit funcional `91e0111` publicado en `main`.
- GitHub Pages ejecutó el SHA exacto en el run `29214230772` y terminó correctamente.
- La URL pública respondió HTTP 200 después del despliegue.
