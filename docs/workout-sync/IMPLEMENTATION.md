# Implementación de sincronización de entrenamientos

## Fase 1: Modelo y HealthKit

- Añadir `WorkoutEntry` a SwiftData.
- Solicitar lectura de entrenamientos, energía activa y distancias.
- Consultar los últimos 30 días y conservar aplicación de origen.
- Insertar o actualizar sin duplicados.

Éxito: Caltrack representa entrenamientos de Salud con duración, calorías, distancia y fuente.

## Fase 2: Hevy detallado

- Añadir cliente REST para `/v1/workouts`.
- Guardar la clave en Keychain.
- Decodificar ejercicios y series de forma tolerante.
- Calcular volumen, mejor serie y total de series.
- Enriquecer o sustituir el resumen de Salud equivalente.

Éxito: un fixture de Hevy se convierte en un entrenamiento local completo.

## Fase 3: Producto

- Añadir tarjeta semanal de entrenamientos.
- Mostrar fuente, duración, distancia, calorías, volumen y ejercicios.
- Explicar cómo activar Strava y Hevy con Salud.
- Añadir sincronización manual y automática.

Éxito: el flujo es comprensible sin conocer HealthKit ni APIs.

## Fase 4: Calidad

- Tests de decodificación, cálculos y deduplicación.
- Test de interfaz para llegar a entrenamientos y ajustes de Hevy.
- Build limpio y revisión visual.
- Verificación real en iPhone cuando Apple permita firmar.

