# Implementación de revisión precisa por foto

## Fase 1: Modelo y migración

- [x] Crear un componente nutricional Codable e identificable.
- [x] Persistir componentes opcionales dentro de `MealEntry`.
- [x] Llevar componentes entre `FoodAnalysis`, `EditableMeal` y `MealEntry`.
- [x] Mantener comidas antiguas como lista vacía.
- [x] Cubrir suma, codificación y migración con tests.

### Criterio

Una comida puede conservar su desglose sin cambiar los totales actuales ni impedir que abra una base v1.8.

## Fase 2: Copia privada

- [x] Añadir componentes opcionales al formato de backup v1.
- [x] Exportar componentes confirmados.
- [x] Restaurarlos sin duplicados.
- [x] Decodificar una copia antigua sin ese campo.

### Criterio

La copia sigue siendo retrocompatible y una restauración mantiene el plato editable.

## Fase 3: Editor nativo

- [x] Crear una vista reutilizable con divulgación progresiva.
- [x] Editar nombre, porción, calorías, proteína, carbohidratos, grasa y fibra opcional.
- [x] Añadir y eliminar componentes.
- [x] Sincronizar totales al editar y ofrecer recálculo explícito.
- [x] Reutilizar el editor al modificar comidas guardadas.

### Criterio

La revisión mantiene la foto, el contexto y una sola acción Guardar, con los detalles avanzados disponibles sin ruido inicial.

## Fase 4: Calidad y publicación

- [x] Añadir fixture visual sin consumir API.
- [x] Probar accesibilidad, lista vacía y componentes largos.
- [x] Inspeccionar capturas en iPhone 16.
- [x] Ejecutar suite completa y build firmado.
- [x] Validar migración v1.8 a v1.9.
- [x] Actualizar documentación.
- [x] Publicar.

### Criterio

El flujo es legible, los totales son deterministas, la base y las copias sobreviven a la actualización y el SHA publicado tiene evidencia completa.
