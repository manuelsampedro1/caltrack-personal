# Velocidad diaria y escritura nutricional

## Objetivo

Reducir fricción en el uso diario y completar la integración Apple. La mayoría de días una persona repite varias comidas, necesita encontrar registros antiguos y quiere evitar escribir los mismos macros en distintas aplicaciones.

## Problemas detectados

- Cada comida exige foto o formulario aunque ya se haya registrado muchas veces.
- El historial crece, pero no tiene búsqueda.
- La primera apertura no explica en diez segundos la relación entre foto, Salud, Hevy y Grok.
- Caltrack lee actividad desde Salud, pero las comidas confirmadas no pueden compartirse opcionalmente con Salud.

## Solución

### Comidas frecuentes

Se agrupan localmente los últimos 90 días por nombre normalizado. Se muestra la versión más reciente de las seis comidas más repetidas. Repetir crea un registro nuevo con la hora actual y sin duplicar la fotografía.

### Búsqueda

El tab Progreso usa `.searchable` para filtrar nombre, fuente y fecha visible. Las acciones de editar, repetir y eliminar se mantienen en el menú de cada fila.

### Onboarding

Una pantalla breve y opcional explica las tres promesas del producto. No solicita permisos al iniciar. Salud y notificaciones se piden únicamente cuando la persona toca su control, siguiendo el contexto de Apple.

### Nutrición en Apple Salud

La opción está desactivada por defecto. Cuando se habilita, solicita permiso de escritura para energía dietética, proteína, carbohidratos, grasa y correlaciones de comida. Cada comida se guarda como una correlación de HealthKit con `HKMetadataKeyExternalUUID` igual al identificador local.

Antes de guardar o editar se elimina cualquier correlación anterior de Caltrack con el mismo identificador. Así la operación es idempotente. Al borrar una comida local también se borra su correlación, si existe.

## Privacidad

- No se pide lectura de nutrición.
- No se importa comida de otras aplicaciones.
- Solo se escriben registros que el usuario confirmó en Caltrack.
- Desactivar la opción impide futuras escrituras, pero no borra silenciosamente datos históricos de Salud.
- La sincronización completa existente se inicia mediante un botón explícito.

## Diseño

- La repetición aparece como una banda horizontal compacta entre captura y resumen diario.
- Cada sugerencia muestra nombre, kcal y proteína.
- El onboarding usa el mismo carbón y verde, una sola pantalla y un botón primario.
- El ajuste de Salud usa un toggle, explicación y estado de error recuperable.
- Haptics ligeros confirman repetición y sincronización.

## Referencias

- [Guardar datos en HealthKit](https://developer.apple.com/documentation/healthkit/saving-data-to-healthkit)
- [Muestras de cantidad](https://developer.apple.com/documentation/healthkit/hkquantitysample)
- [Energía dietética y macronutrientes](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/dietaryenergyconsumed)
- [Metadata de HealthKit](https://developer.apple.com/documentation/healthkit/metadata-keys)
- [Onboarding de Apple](https://developer.apple.com/design/human-interface-guidelines/onboarding)
- [Búsqueda en SwiftUI](https://developer.apple.com/documentation/swiftui/search)
