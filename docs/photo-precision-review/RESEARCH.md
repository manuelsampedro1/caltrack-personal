# Revisión precisa de comidas por foto

## Problema

La foto es la acción principal de Caltrack. Grok ya devuelve componentes visibles, porciones y macros, pero la interfaz actual muestra ese desglose como texto de solo lectura. Si el arroz, el aceite o la cantidad de carne están mal, el usuario solo puede corregir el total completo y pierde la relación entre plato y números.

La mejora debe permitir corregir cada parte del plato sin convertir una foto rápida en una hoja de cálculo.

## Casos de uso

- Cambiar `150 g de pollo` por `220 g de pollo` y ajustar sus macros.
- Añadir aceite, salsa o una bebida que no aparece con claridad.
- Eliminar un componente detectado por error.
- Recalcular los totales desde los componentes con un toque.
- Mantener un ajuste final manual cuando la suma conocida es más fiable.
- Volver a editar más tarde el mismo desglose desde el historial.
- Exportar y restaurar el desglose sin romper copias anteriores.

## Referencias

1. El Caltrack original de Pieter Levels: foto, cálculo con Grok y confirmación enfocada en déficit y proteína.
2. MacroFactor: permite expandir una receta en ingredientes y editar cantidades sin perder el total del plato.
3. Apple Human Interface Guidelines: `DisclosureGroup` para ocultar detalle hasta que sea relevante y mantener la acción principal visible.

## Opciones técnicas

### Editar solo antes de guardar

Es la opción más pequeña, pero el desglose desaparece al confirmar. Una corrección futura vuelve a depender de memoria o de la foto.

### Guardar texto libre con el desglose

Evita una migración compleja, pero no permite reconstruir campos editables ni verificar sumas con seguridad.

### Guardar componentes Codable en almacenamiento externo

Cada comida conserva una lista pequeña de componentes con nombre, porción, calorías, proteína, carbohidratos y grasa. SwiftData guarda el JSON opcional mediante `externalStorage`, como ya hace con fotos y ejercicios. Las comidas antiguas siguen siendo válidas con una lista vacía.

Esta es la opción elegida. Mantiene la base local, no añade tablas relacionadas ni backend y permite una migración ligera.

## Diseño

### Referencias visuales

- resultado actual de Grok en Caltrack
- edición expandible de ingredientes de MacroFactor
- controles de divulgación y formularios nativos de Apple

### Sistema visual

- paleta actual: carbón, verde, azul y coral
- tipografía del sistema, números monoespaciados para macros
- spacing de 8, 12 y 16 puntos
- SF Symbols: `fork.knife`, `plus`, `trash`, `sum`
- una tarjeta por componente, sin navegación adicional
- `DisclosureGroup` abierto tras una foto y cerrado al editar una comida antigua

### Estados

- análisis con componentes detectados
- componente añadido manualmente
- lista vacía
- campo inválido tratado como cero sin bloquear el resto
- total sincronizado con componentes
- total ajustado manualmente
- comida antigua sin desglose
- reducción de movimiento respetada, sin animaciones decorativas

### Interacción

- editar un componente actualiza los totales en tiempo real
- borrar o añadir usa haptic ligero
- `Recalcular total` restaura la suma si el usuario cambió el total final
- guardar sigue siendo una única acción principal

## Datos y privacidad

El desglose se queda en el almacenamiento local y en la copia privada. No añade llamadas a Grok. No contiene claves, identificadores de Salud ni nuevos permisos.

## Integraciones

- `FoodAnalysis.Item` alimenta el editor.
- `EditableMeal` conserva borradores editables.
- `MealEntry` persiste componentes opcionales.
- dashboard, progreso y repetición siguen usando los totales confirmados.
- HealthKit recibe únicamente los totales finales.
- backup incluye componentes opcionales y decodifica copias antiguas.

## Riesgos

- Una suma automática no convierte la estimación visual en una medición exacta. La UI mantiene el aviso.
- El teclado puede hacer el flujo largo. El detalle avanzado queda dentro de divulgación progresiva.
- La migración debe comprobar datos reales de v1.8 antes y después.

## Referencias técnicas

- [xAI Image Understanding](https://docs.x.ai/developers/model-capabilities/images/understanding)
- [xAI Structured Outputs](https://docs.x.ai/developers/model-capabilities/text/structured-outputs)
- [Apple Disclosure Controls](https://developer.apple.com/design/human-interface-guidelines/disclosure-controls)
- [MacroFactor, expandir ingredientes](https://help.macrofactorapp.com/en/articles/215-how-to-log-food-in-macrofactor)
