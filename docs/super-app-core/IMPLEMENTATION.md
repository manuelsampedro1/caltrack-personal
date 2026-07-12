# Implementación del núcleo de super app

## Fase 1: Navegación y captura completa

- [x] Crear tabs Hoy, Progreso y Entrenador.
- [x] Mantener la cámara como acción primaria.
- [x] Añadir registro manual accesible directamente.
- [x] Conservar ajustes como sheet.

### Criterio

Las tres áreas se alcanzan con un toque y se puede guardar comida con o sin IA.

## Fase 2: Progreso e historial

- [x] Crear gráficos de nutrición de 14 días.
- [x] Crear tendencias de peso, grasa y cintura.
- [x] Resumir frecuencia, duración y volumen de entrenamiento.
- [x] Mostrar historial de comidas y permitir editar o eliminar registros.

### Criterio

El usuario puede entender nutrición, cuerpo y entrenamiento sin depender de otra app.

## Fase 3: Entrenador con Grok

- [x] Crear observaciones deterministas locales.
- [x] Construir un contexto limitado y legible de 30 días.
- [x] Enviar preguntas voluntarias a xAI con `store: false`.
- [x] Guardar conversación local y ofrecer prompts rápidos.

### Criterio

El entrenador funciona localmente sin clave y ofrece preguntas profundas cuando xAI está configurado.

## Fase 4: Salud, copia y recordatorios

- [x] Importar historial reciente de composición corporal desde HealthKit.
- [x] Importar energía activa, basal y pasos para estimar balance.
- [x] Exportar todos los datos de la app a JSON privado.
- [x] Restaurar o fusionar una copia sin duplicar registros.
- [x] Programar un recordatorio local diario opcional.

### Criterio

Los datos se pueden recuperar, las tendencias se llenan desde Salud y los recordatorios no requieren servidor.

## Fase 5: Calidad

- [x] Añadir tests de cálculos, backup, contexto del entrenador e historial de Salud.
- [x] Probar navegación y funciones principales en UI tests.
- [x] Ejecutar build y tests sin warnings propios.
- [x] Inspeccionar cada tab y los estados vacíos con capturas.
- [x] Actualizar privacidad, decisiones y documentación.
