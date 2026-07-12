# Progreso de escaneo de productos

## Estado: completado

## Decisiones

- AVFoundation en lugar de un SDK comercial.
- Open Food Facts v3 para lectura directa por código.
- Valores colaborativos siempre editables y atribuidos.
- Sin imágenes remotas para reducir transferencia y superficie de licencia.
- Entrada manual disponible en todos los estados.

## Evidencia inicial

- La API v3 devolvió un producto real con energía y macros por 100 g.
- La documentación oficial exige User-Agent y limita lecturas a 15 por minuto.
- No se requiere autenticación para consultar un producto.

## Evidencia de implementación

- Build de simulador completado correctamente.
- 22 pruebas superadas en la suite completa, 16 unitarias y 6 de interfaz.
- Flujo UI de código, producto, edición y guardado superado sin cámara ni red.
- El flujo de código se repitió 3 veces desde una instalación limpia sin fallos.
- Captura visual revisada en tamaño de texto normal, sin cortes ni controles ocultos.
- Suite integral desde una instalación limpia: 22 superadas, 0 fallos, 0 omitidas.

## Bloqueos

- El escaneo real con cámara seguirá necesitando la app firmada en un iPhone.
