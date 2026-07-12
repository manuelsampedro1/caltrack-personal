# Implementación de recuperación

## Fase 1: Modelo y cálculo

- [x] Añadir `RecoveryDay` al esquema persistente.
- [x] Crear snapshots y segmentos de sueño testeables.
- [x] Unir intervalos solapados y seleccionar una fuente por noche.
- [x] Mantener compatibilidad con copias v1 anteriores.

### Criterio

Los cálculos no duplican sueño y una copia antigua sigue restaurando.

## Fase 2: HealthKit

- [x] Solicitar sueño, frecuencia en reposo y HRV en contexto.
- [x] Leer 30 días de sueño y promedios diarios de cantidades discretas.
- [x] Persistir por identificador diario estable.
- [x] Incluir fixtures de simulador.

### Criterio

Sin datos o sin permiso, la app continúa funcionando y muestra un estado vacío veraz.

## Fase 3: Interfaz

- [x] Diseñar tarjeta compacta con tres métricas.
- [x] Añadir selector y gráfica de 14 días.
- [x] Mostrar comparación descriptiva con la tendencia personal.
- [x] Verificar texto accesible y ausencia de score médico.

### Criterio

La recuperación se entiende en menos de diez segundos y no desplaza la acción principal de Hoy.

## Fase 4: Calidad

- [x] Probar agregación, persistencia y backup.
- [x] Probar la tarjeta en UI con datos y estado vacío.
- [x] Probar migración desde v1.5.
- [x] Ejecutar build y suite completa.
- [x] Actualizar privacidad, decisiones, README y TODO.
- [x] Publicar v1.6 y verificar el SHA exacto.
