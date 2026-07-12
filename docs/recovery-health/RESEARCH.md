# Recuperación desde Apple Salud

## Problema

Caltrack reúne comida, cuerpo y entrenamiento, pero todavía obliga a abrir Salud u otra app para entender el contexto de recuperación. El dato útil no es un score opaco, sino ver sueño, frecuencia cardiaca en reposo y variabilidad cardiaca junto al entrenamiento y la dieta.

## Fuentes disponibles

HealthKit expone:

- `sleepAnalysis` como muestras categóricas de tiempo en cama, despierto, sueño esencial, profundo, REM o no especificado.
- `restingHeartRate` como cantidad discreta en latidos por minuto.
- `heartRateVariabilitySDNN` como SDNN, normalmente expresada en milisegundos.

Apple explica que los intervalos de tiempo en cama pueden solaparse con las fases de sueño. Caltrack contará únicamente valores dormidos y unirá intervalos antes de sumar para evitar duplicados. Cuando varias fuentes describan la misma noche, conservará la fuente con más tiempo dormido para ese día.

## Producto

La tarjeta Recuperación vivirá en Progreso, después del balance energético. Mostrará:

1. Sueño total de la última noche disponible.
2. Frecuencia cardiaca en reposo más reciente.
3. HRV SDNN más reciente.
4. Una gráfica de 14 días seleccionable por métrica.
5. Comparación descriptiva con la media personal, sin diagnóstico ni recomendación de entrenamiento automática.

## Límites

- No se crea un score de disposición o recuperación.
- No se usan umbrales clínicos universales.
- La ausencia de un dato no se interpreta como un problema.
- Las tendencias dependen del dispositivo, el uso nocturno y los permisos elegidos.
- Los datos permanecen locales y no se envían a xAI por añadir esta función.

## Arquitectura

- `RecoveryDay`: caché local diaria en SwiftData.
- `RecoverySnapshot`: resultado inmutable de HealthKit.
- `RecoveryMath`: unión de intervalos, agrupación por día de despertar y selección de fuente.
- `HealthKitService`: lectura de 30 días de sueño y medias diarias de frecuencia en reposo y HRV.
- `DashboardView`: fusión idempotente en SwiftData al sincronizar Salud.
- `ProgressDashboardView`: tarjeta y gráfica de 14 días.
- `BackupService`: recuperación opcional compatible con copias v1 anteriores.

## Referencias oficiales

- [Análisis de sueño](https://developer.apple.com/documentation/healthkit/hkcategoryvaluesleepanalysis)
- [Identificador sleepAnalysis](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/sleepanalysis)
- [HRV SDNN](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/heartratevariabilitysdnn)
- [Consultas estadísticas](https://developer.apple.com/documentation/healthkit/executing-statistics-collection-queries)
- [HKStatistics](https://developer.apple.com/documentation/healthkit/hkstatistics)
