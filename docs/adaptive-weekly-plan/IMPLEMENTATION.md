# Implementación del plan semanal adaptativo

## Fase 1: Modelo y motor

- [x] Añadir `DailyPlanCheckIn` al esquema persistente.
- [x] Crear tipos puros para días completos, pesos y resultado de revisión.
- [x] Calcular tendencia por regresión y adherencia al rango.
- [x] Cubrir estados sin datos, sin adherencia y con ajuste de 100 kcal.

### Criterio

El motor siempre explica su evidencia y nunca propone un cambio con datos insuficientes.

## Fase 2: Cierre diario

- [x] Añadir una acción compacta dentro de Hoy.
- [x] Presentar hambre y energía mediante controles nativos.
- [x] Permitir editar o reabrir el cierre del día.
- [x] Dar feedback háptico y accesible.

### Criterio

Cerrar el día requiere como máximo tres interacciones y no bloquea registrar otra comida después.

## Fase 3: Revisión y configuración

- [x] Diseñar la tarjeta semanal con estado, evidencia y recomendación.
- [x] Añadir una sheet para modo, ritmo y peso objetivo opcional.
- [x] Aplicar cambios solo después de confirmación explícita.
- [x] Mostrar el rango anterior y el nuevo antes de aplicar.

### Criterio

La recomendación se entiende en menos de diez segundos y distingue falta de datos, falta de adherencia y ajuste real.

## Fase 4: Persistencia y calidad

- [x] Incluir check-ins y configuración en la copia privada.
- [x] Mantener restauración de copias v1 sin los nuevos campos.
- [x] Probar migración desde v1.6 sin perder datos.
- [x] Añadir fixtures, unit tests y un recorrido de interfaz dentro de la suite completa.
- [x] Verificar visualmente tamaño normal y hojas en pantalla compacta.
- [x] Actualizar README, privacidad, decisiones y TODO.
- [ ] Publicar v1.7 y verificar el SHA exacto.
