# Decisiones

## 2026-07-11

### Una sola fuente de verdad en el dispositivo

IndexedDB guarda comidas, peso, ejercicio, fotos y objetivos directamente en el navegador. Esto resuelve el fallo principal del flujo basado solo en chat: la memoria deja de depender del tamaño de una conversación.

### Web instalable sin servidor

La interfaz usa HTML, CSS, JavaScript e IndexedDB nativos. GitHub Pages sirve archivos estáticos y nunca recibe los datos del usuario. El service worker permite abrir Caltrack sin conexión después de la primera visita.

### Estimaciones visibles

El catálogo interno cubre alimentos frecuentes en español e inglés. Cada estimación conserva su cantidad asumida. Un alimento desconocido necesita calorías explícitas. Nunca se rellena un valor inventado en silencio.

### Rangos por día

Caltrack usa rangos absolutos de calorías y proteína porque son más útiles que recalcularlos desde un peso posiblemente desactualizado. Peso y mantenimiento quedan opcionales. Si falta mantenimiento, la app muestra una referencia derivada del máximo calórico más el déficit configurado.

### Privacidad y portabilidad

No hay autenticación porque no hay datos remotos. Cada navegador conserva su historial de forma aislada. Una copia JSON privada permite mover perfil, registros y fotos entre dispositivos. El CSV permite análisis externo.

### Diseño

Se replica el sistema visual del tuit: negro cálido, tarjetas carbón, verde para éxito, coral para exceso, azul para proteína, barras semanales y filas densas. La captura rápida se coloca antes del gráfico porque el valor diario empieza por registrar sin fricción.

## 2026-07-12

### Progreso útil para el objetivo físico

La pantalla principal añade tendencia de composición corporal, objetivo semanal de fuerza y cinco ejercicios comparables. El criterio es ver dirección y adherencia, no reaccionar a una medición aislada.

### Importación privada

El historial personal se entrega en un QR local ignorado por Git. El contenido viaja en el fragmento de la URL, no llega a GitHub Pages, se guarda en IndexedDB y el fragmento se elimina de la barra antes de mostrar la confirmación. No se incluyen fármacos, dosis ni recomendaciones médicas.

### Cliente iOS para foto y Salud

Una PWA no puede acceder a HealthKit. Caltrack mantiene la web y añade un cliente SwiftUI local-first para iOS 17+. SwiftData guarda comidas y fotos, HealthKit lee únicamente peso, grasa corporal y cintura con permiso, y Keychain protege la clave de xAI.

La foto es la acción principal. Grok devuelve un JSON estricto con componentes, porciones, macros, confianza y supuestos. Nada se guarda hasta que el usuario revisa y confirma la estimación.

### Pase de diseño

Las referencias son las capturas del tuit original, la PWA ya publicada y las guías de HealthKit de Apple. La app conserva carbón casi negro, verde para acciones y éxito, azul para proteína y coral para advertencias. Usa SF Symbols, tarjetas de 20 puntos, espacios de 14 a 18 puntos, haptics ligeros, sheets nativas y soporte de Reduce Motion sin dependencias de UI.
