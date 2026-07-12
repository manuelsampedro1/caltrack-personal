# Escaneo de productos envasados

## Visión general

Caltrack ya resuelve platos con foto, entradas exactas y comidas frecuentes. El hueco diario más claro son los productos envasados: copiar una etiqueta consume tiempo y volver a enviar una foto a Grok es innecesario cuando el fabricante ya declara los nutrientes.

## Problema

- Un yogur, bebida o snack con código de barras requiere una foto o entrada manual.
- Una estimación visual es menos adecuada que los valores de la etiqueta.
- Añadir otra API privada o un backend rompería el enfoque local-first.

## Casos de uso

1. Tocar Código, enfocar el envase y obtener nombre y macros por 100 g.
2. Indicar la cantidad realmente consumida y recalcular los macros.
3. Corregir cualquier valor antes de guardar.
4. Introducir el código a mano si la cámara no está disponible.
5. Pasar directamente a registro manual si el producto no existe o sus datos están incompletos.

## Opciones técnicas

### SDK comercial de nutrición

Ventajas: catálogo mantenido y soporte empresarial.

Desventajas: coste, clave adicional, seguimiento y dependencia innecesaria para una app personal.

### VisionKit con DataScanner

Ventajas: interfaz de escaneo de alto nivel.

Desventajas: disponibilidad limitada por dispositivo y peor control sobre el fallback de simulador.

### AVFoundation y Open Food Facts

Ventajas: APIs nativas, sin SDK, sin cuenta para lectura y sin VPS. `AVCaptureMetadataOutput` detecta códigos y Open Food Facts ofrece nutrientes por código.

Desventajas: los datos son colaborativos y pueden estar incompletos. La API limita lecturas de producto a 15 por minuto e exige identificar la app con User-Agent.

## Recomendación

Usar AVFoundation para EAN, UPC y códigos lineales comunes. Consultar la API v3 de Open Food Facts una sola vez por escaneo, con User-Agent identificable y campos limitados. Nunca guardar automáticamente: mostrar cantidad, origen y macros editables.

## Datos

No se necesita un modelo persistente nuevo. La comida confirmada reutiliza `MealEntry` con:

- `source`: `Open Food Facts`
- `assumption`: código, cantidad consumida y aviso de datos colaborativos
- macros calculados desde valores por 100 g

El código se envía a Open Food Facts solo al escanear o buscar. No se envían fotos, datos de Salud, entrenamientos ni otras comidas.

## Diseño

Referencias:

1. Caltrack original: una acción principal de foto y utilidades compactas.
2. Cámara de Apple: visor completo, marco central y respuesta háptica al detectar.
3. Open Food Facts: código, producto, nutrientes y un estado claro cuando falta información.

Se mantiene la paleta carbón, verde, azul y coral. Código aparece junto a Fototeca y Manual. El resultado usa una sheet nativa, cantidad editable, resumen por 100 g, estado de carga, error y fallback manual.

## Riesgos

- Datos incorrectos: mostrar atribución, aviso y edición obligatoria antes de guardar.
- Lecturas repetidas: detener la sesión al primer código y bloquear búsquedas simultáneas.
- Cámara denegada: mantener entrada manual visible.
- Producto sin macros: ofrecer registro manual sin inventar valores.
- Privacidad: enviar únicamente el código y documentarlo.

## Referencias

- [AVCaptureMetadataOutput](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput)
- [Ejemplo AVCamBarcode](https://developer.apple.com/documentation/AVFoundation/avcambarcode-detecting-barcodes-and-faces)
- [API de Open Food Facts](https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/)
- [Producto por código, API v3](https://openfoodfacts.github.io/documentation/docs/Product-Opener/v3/products/get-api-v3-product-code/)
- [Buenas prácticas de escaneo](https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/tutorials/scanning-barcodes/)
