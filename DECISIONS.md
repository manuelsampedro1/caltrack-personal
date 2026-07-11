# Decisiones

## 2026-07-11

### Una sola fuente de verdad en el dispositivo

IndexedDB guarda comidas, peso, ejercicio, fotos y objetivos directamente en el navegador. Esto resuelve el fallo principal del flujo basado solo en chat: la memoria deja de depender del tamaño de una conversación.

### Web instalable sin servidor

La interfaz usa HTML, CSS, JavaScript e IndexedDB nativos. GitHub Pages sirve archivos estáticos y nunca recibe los datos del usuario. El service worker permite abrir Caltrack sin conexión después de la primera visita.

### Estimaciones visibles

El catálogo interno cubre alimentos frecuentes en español e inglés. Cada estimación conserva su cantidad asumida. Un alimento desconocido necesita calorías explícitas. Nunca se rellena un valor inventado en silencio.

### Objetivo por día

El mantenimiento base viene del perfil. El gasto de un entrenamiento registrado se suma al mantenimiento del día. El objetivo diario resta el déficit configurado. Un override diario queda previsto en la base para casos especiales.

### Privacidad y portabilidad

No hay autenticación porque no hay datos remotos. Cada navegador conserva su historial de forma aislada. Una copia JSON privada permite mover perfil, registros y fotos entre dispositivos. El CSV permite análisis externo.

### Diseño

Se replica el sistema visual del tuit: negro cálido, tarjetas carbón, verde para éxito, coral para exceso, azul para proteína, barras semanales y filas densas. La captura rápida se coloca antes del gráfico porque el valor diario empieza por registrar sin fricción.
