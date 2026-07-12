# Progreso de check-ins corporales

## Estado: completado

## Decisiones

- El check-in vive en Progreso, junto a la tendencia corporal.
- La foto es opcional y nunca se analiza ni se sube.
- Se usa PhotosPicker, sin permiso general sobre la fototeca.
- La imagen se limita a 1600 píxeles y JPEG de calidad 0,82.
- El backup mantiene versión 1 y añade un campo opcional.
- Las muestras importadas de Salud no se pueden editar desde Caltrack.

## Evidencia inicial

- Apple documenta que PhotosPicker solo entrega los elementos elegidos.
- SwiftData permite guardar binarios adyacentes mediante `externalStorage`.
- La tarjeta de composición ya dispone de tendencia y es el punto natural de entrada.

## Evidencia de implementación

- Build de simulador completado correctamente.
- Validación parcial, compresión a 1600 píxeles y backup con foto superan pruebas unitarias.
- Una copia versión 1 sin `photoData` se decodifica correctamente.
- Creación, edición, galería y visor superan un recorrido UI con texto accesible.
- Capturas de la tarjeta y del visor inspeccionadas visualmente.
- Migración real desde el commit 1.3: 6 de 6 mediciones conservadas y columna de foto creada.
- La tendencia diaria elimina duplicados visuales sin borrar los registros de origen.
- Suite completa desde instalación limpia: 26 pruebas superadas, 0 fallos y 0 omitidas.
- Desglose final: 19 pruebas unitarias y 7 recorridos de interfaz.
- Build 1.4, número 5, sin warnings propios.

## Bloqueos

- La selección desde la fototeca real seguirá necesitando la app instalada en iPhone para su validación final.
