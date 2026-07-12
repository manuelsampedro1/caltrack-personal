# Plan de escaneo de productos envasados

## Fase 1: Servicio determinista

- [x] Modelar un producto de Open Food Facts.
- [x] Decodificar la respuesta v3 y validar macros mínimos.
- [x] Escalar valores por 100 g a la cantidad consumida.
- [x] Identificar la app con User-Agent y limitar campos.

## Fase 2: Cámara y fallback

- [x] Crear un lector nativo con AVFoundation.
- [x] Detectar EAN, UPC y códigos lineales comunes.
- [x] Detener la captura después de una lectura.
- [x] Ofrecer entrada manual cuando cámara o permiso fallen.

## Fase 3: Confirmación

- [x] Añadir Código al bloque de captura.
- [x] Mostrar carga, producto no encontrado y errores recuperables.
- [x] Permitir cambiar cantidad y editar todos los macros.
- [x] Guardar con fuente y supuestos verificables.

## Fase 4: Calidad

- [x] Añadir tests de decodificación y escalado.
- [x] Añadir un flujo UI determinista sin cámara ni red.
- [x] Probar tamaño de letra accesible.
- [x] Actualizar privacidad, decisiones y README.
- [x] Build y suite completa sin warnings propios.

## Criterios de éxito

- Un producto conocido pasa de código a comida editable.
- Un producto desconocido nunca genera macros inventados.
- La app no necesita clave, SDK ni backend nuevo.
- El registro conserva los flujos de Salud y backup existentes.
