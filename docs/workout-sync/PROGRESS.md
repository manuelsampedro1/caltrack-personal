# Progreso de sincronización de entrenamientos

## Estado: implementación terminada, verificación externa bloqueada

## 2026-07-12

- Se verificó que Strava puede enviar actividades a Apple Salud.
- Se verificó que Hevy puede enviar entrenamientos a Salud, pero sin detalle completo de series.
- Se verificó que la API oficial de Hevy ofrece entrenamientos, eventos, historial de ejercicios y medidas para usuarios Pro.
- Se eligió HealthKit como bandeja universal y Hevy API como enriquecimiento opcional.
- HealthKit ya importa entrenamientos, duración, calorías, distancia y app de origen de los últimos 30 días.
- Hevy Pro ya puede enriquecerlos con rutina, ejercicios, series, repeticiones, carga, RPE, volumen y mejor serie.
- La sincronización evita duplicar el resumen de Salud y el entrenamiento detallado de Hevy.
- El dashboard muestra entrenamientos semanales, fuente, métricas principales y detalle de fuerza.
- La clave de Hevy se guarda en Keychain y no entra en SwiftData ni en el repositorio.
- Pasan 4 tests unitarios y 1 test de interfaz, con 0 fallos.
- La tarjeta poblada fue inspeccionada visualmente en un simulador iPhone 16.

## Bloqueos externos

- No hay una clave de Hevy configurada.
- El iPhone está desconectado.
- La sesión Apple de Xcode necesita renovarse antes de probar HealthKit en el dispositivo.
