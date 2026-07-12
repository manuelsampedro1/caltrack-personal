# Sincronización de entrenamientos

## Resumen

Caltrack debe reunir los entrenamientos que Manuel registra en Hevy y Strava sin obligarle a duplicar datos. La solución debe conservar privacidad, funcionar sin VPS y aportar detalle útil para progreso físico.

## Casos de uso

- Ver automáticamente carreras, ciclismo y otras actividades de Strava.
- Ver entrenamientos de fuerza registrados en Hevy.
- Conocer duración, distancia, calorías y aplicación de origen.
- Recuperar desde Hevy ejercicios, series, repeticiones, cargas, RPE, volumen y mejores series.
- Evitar duplicados cuando un entrenamiento aparece tanto en Salud como en la API de Hevy.

## Opciones

### Solo Apple Salud

Strava puede enviar a Salud tipo, ruta, distancia, tiempo y calorías. Hevy también envía entrenamientos y calorías, pero los clasifica como fuerza y no expone en HealthKit las series o cargas completas.

Ventajas: permisos nativos, datos locales, sin claves adicionales y compatible con otras aplicaciones futuras.

Límite: se pierde el detalle específico de Hevy.

### APIs directas de Hevy y Strava

Hevy ofrece una API oficial para usuarios Pro con entrenamientos completos. Strava requiere registrar una aplicación, OAuth y normalmente un callback o backend para renovar tokens y recibir webhooks.

Ventaja: máximo detalle de cada plataforma.

Límite: más credenciales, mantenimiento y superficie de privacidad.

### Solución híbrida recomendada

HealthKit será la fuente universal para resúmenes de entrenamientos. La API oficial de Hevy será un enriquecimiento opcional para fuerza. No se integra directamente Strava porque Salud ya aporta los datos necesarios para Caltrack y evita OAuth, secretos y backend.

## Datos

`WorkoutEntry` guarda identificador externo, fechas, título, tipo, duración, calorías, distancia, fuente, número de ejercicios, series, volumen y un resumen JSON de ejercicios.

La deduplicación usa el identificador de HealthKit o Hevy y, cuando cambian de fuente, una ventana temporal alrededor del inicio del entrenamiento.

## Privacidad

- HealthKit se consulta localmente con permiso explícito.
- La clave de Hevy se guarda en Keychain y nunca se incluye en Git o backups.
- No se solicita una clave de Strava.
- Los entrenamientos no se envían a xAI durante la sincronización.

## Riesgos

- La API de Hevy está marcada como experimental y puede cambiar.
- Hevy API requiere una cuenta Pro.
- Las actividades antiguas no siempre se sincronizan retroactivamente a Salud.
- La lectura real sigue bloqueada hasta renovar la sesión Apple y conectar el iPhone.

## Referencias

- [API oficial de Hevy](https://api.hevyapp.com/docs/)
- [Hevy y Apple Salud](https://help.hevyapp.com/hc/en-us/articles/36957445562775-Hevy-Not-Syncing-to-Apple-Health-Step-by-Step-Troubleshooting-Guide)
- [Strava y Apple Salud](https://support.strava.com/es/articles/15402024-app-salud-y-strava)
- [HKWorkout](https://developer.apple.com/documentation/healthkit/hkworkout)
- [Fuentes de HealthKit](https://developer.apple.com/documentation/healthkit/hksourcerevision)

