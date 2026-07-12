# Progreso del plan semanal adaptativo

## Estado: v1.7 validada y publicada

## Decisiones

- Ajustes de 100 kcal, nunca automáticos.
- Regresión lineal para reducir el ruido de mediciones aisladas.
- Solo cuentan días que el usuario marque como completos.
- Sin fórmula de metabolismo, edad, sexo o altura.
- La foto sigue siendo la acción principal de Hoy.
- No se crea una pestaña adicional.

## Evidencia

- La app actual ya ofrece datos suficientes para cerrar el bucle, pero sus objetivos solo se editan manualmente.
- El NIH usa un modelo dinámico con información personal, lo que desaconseja una aproximación simplista de metabolismo.
- Apple acepta usar peso y actividad para personalizar objetivos si el acceso es relevante, consentido y transparente.
- Los check-ins semanales son un patrón validado para proponer cambios sin alterar objetivos a diario.

- Suite limpia superada: 29 tests unitarios y 11 recorridos de interfaz, 40 de 40.
- Recorrido adaptativo superado sin reintentos: cierre, hambre, energía, configuración, propuesta y confirmación.
- Hojas y tarjeta revisadas visualmente con capturas reales del simulador.
- La restauración acepta copias antiguas sin check-ins ni configuración de plan.
- La copia conserva también la fecha del último ajuste para respetar la pausa después de restaurar.
- Los rangos se ordenan de forma segura aunque una copia antigua contenga mínimo y máximo invertidos.
- Migración instalada de v1.6 build 7 a v1.7 build 8 sin desinstalar: 42 comidas, 6 medidas, 14 días de actividad, 14 de recuperación y 4 entrenamientos preservados. La tabla nueva se creó vacía.

## Archivos implementados

- `ios/Caltrack/Models.swift`
- `ios/Caltrack/AdaptivePlanEngine.swift`
- `ios/Caltrack/DailyPlanCheckInSheet.swift`
- `ios/Caltrack/PlanSettingsSheet.swift`
- `ios/Caltrack/DashboardView.swift`
- `ios/Caltrack/BackupService.swift`
- tests y documentación

## Evidencia de release

- Commit funcional: `63afd77a36f9797a78401c2321168f2e07845240`.
- GitHub Pages run `29211586252` completado correctamente para ese SHA.
- URL pública comprobada con HTTP 200.
