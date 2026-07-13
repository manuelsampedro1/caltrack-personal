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

Una PWA no puede acceder a HealthKit. Caltrack mantiene la web y añade un cliente SwiftUI local-first para iOS 17+. SwiftData guarda comidas, fotos y entrenamientos, HealthKit lee peso, grasa corporal, cintura y actividad con permiso, y Keychain protege las claves personales.

La foto es la acción principal. Grok devuelve un JSON estricto con componentes, porciones, macros, confianza y supuestos. Nada se guarda hasta que el usuario revisa y confirma la estimación.

### Pase de diseño

Las referencias son las capturas del tuit original, la PWA ya publicada y las guías de HealthKit de Apple. La app conserva carbón casi negro, verde para acciones y éxito, azul para proteína y coral para advertencias. Usa SF Symbols, tarjetas de 20 puntos, espacios de 14 a 18 puntos, haptics ligeros, sheets nativas y soporte de Reduce Motion sin dependencias de UI.

### Salud como bandeja universal de entrenamientos

Strava y Hevy pueden escribir entrenamientos en Apple Salud. Caltrack los consulta desde HealthKit para evitar OAuth, secretos de Strava y un backend. La fuente original se conserva para mostrar si una actividad viene de Hevy, Strava u otra aplicación.

HealthKit no conserva las series, repeticiones y cargas completas de Hevy. Por eso Caltrack admite una clave opcional de Hevy Pro en Keychain, importa el detalle desde la API oficial y fusiona la sesión con su resumen de Salud mediante identificador y hora de inicio.

### Una sola API de IA

Caltrack usa xAI Grok para imagen y salida nutricional estructurada. OpenAI no se añade porque duplicaría coste, claves y transferencia de datos sin resolver una necesidad distinta. La puntuación diaria y los avisos simples siguen siendo deterministas y locales.

### Conexiones visibles y estados veraces

Salud, Hevy y Grok aparecen en un panel compacto antes de la cámara. Salud solo se marca como preparada si HealthKit termina el flujo correctamente. Como Apple no revela si se denegó cada tipo de lectura, la interfaz no afirma acceso total. Hevy y xAI validan la clave antes de guardarla.

### Tres contextos nativos

La app usa tabs Hoy, Progreso y Entrenador. Hoy mantiene captura y decisiones inmediatas. Progreso reúne nutrición, composición, gasto e historial. Entrenador separa reglas locales de preguntas voluntarias a Grok. Esta división evita convertir una única pantalla en un dashboard interminable.

### Balance energético con cautela

Caltrack suma energía activa y basal leídas de Salud y la compara con comidas registradas. Se etiqueta siempre como estimación porque relojes, fórmulas y etiquetas tienen error. La tendencia del peso tiene más peso interpretativo que un balance diario aislado.

### Portabilidad sin cuenta

La app nativa exporta y fusiona un JSON con comidas, fotos, cuerpo, actividad, entrenamientos y conversación. La restauración usa identificadores estables para no duplicar. Keychain queda fuera. Los recordatorios son locales y están desactivados por defecto.

### Repetición antes que análisis repetido

Las comidas de los últimos 90 días se agrupan localmente por nombre normalizado. Las seis más frecuentes reutilizan los valores de su registro más reciente y crean una comida nueva sin copiar la foto. Esto reduce tiempo y evita pagar otra llamada de visión por un plato ya conocido.

### Búsqueda enfocada

Progreso conserva gráficos e historial en la misma pantalla. Al escribir en el buscador, oculta temporalmente los gráficos y lleva los resultados arriba. La búsqueda cubre nombre, fuente y fecha, y mantiene repetir, editar y borrar.

### Introducción sin permisos anticipados

La primera apertura explica foto, Salud, Hevy y tendencias en una pantalla que se puede omitir. No abre permisos del sistema. Cada permiso aparece después de una acción con contexto y la introducción se puede volver a abrir desde Ajustes.

### Escritura nutricional explícita en Salud

Caltrack no lee nutrición. La escritura está desactivada por defecto y usa una correlación de comida con energía, proteína, carbohidratos, grasa y fibra cuando existe. El UUID local se guarda como identificador externo para actualizar sin duplicar y eliminar solo objetos creados por Caltrack. La sincronización del historial necesita una acción explícita.

### Etiqueta antes que IA para productos envasados

Los productos con código se leen con AVFoundation y se consultan en Open Food Facts v3. Esto evita gastar una llamada de Grok y prioriza los valores declarados del envase. No se añade SDK, cuenta, clave ni backend.

Los datos colaborativos nunca se guardan automáticamente. La hoja muestra valores por 100 g, ración, atribución y aviso, y permite corregir nombre, cantidad y todos los macros. Si falta información, Caltrack ofrece registro manual y no inventa valores.

### Check-in corporal independiente de Salud

Salud sigue siendo la fuente automática, pero no todas las básculas escriben grasa y cintura. Progreso permite un check-in manual con campos opcionales y una foto. Los registros manuales se pueden editar; las muestras de Salud permanecen separadas y de solo lectura.

PhotosPicker concede acceso únicamente a la imagen elegida. Caltrack la redimensiona a 1600 píxeles, la comprime localmente y la guarda con `externalStorage`. No se analiza con IA. La copia mantiene versión 1 con `photoData` opcional para restaurar copias anteriores sin migraciones de formato.

La gráfica fusiona solo la representación de métricas del mismo día y conserva los objetos originales. Así evita segmentos verticales cuando coinciden Salud y un check-in, sin perder procedencia ni capacidad de edición.

### Cuatro acciones frecuentes en el sistema

Caltrack expone fotografiar comida, escanear producto, nuevo check-in y abrir progreso mediante App Intents. Son cuatro acciones sin parámetros, dentro del rango de dos a cinco que Apple recomienda para App Shortcuts comunes. Se descubren desde Ajustes, Siri, Spotlight, Atajos y el botón Acción.

Cada intent escribe solo una ruta local de un solo uso. RootView la conserva durante la introducción y la consume cuando puede presentar la pantalla correcta. No se serializan datos nutricionales, corporales o de Salud. En iOS 17 a 25 la acción abre la app con `openAppWhenRun`; en iOS 26 usa el modo de primer plano moderno.

La cámara configura `cameraCaptureMode` únicamente cuando el hardware está disponible. En simulador y otros entornos sin cámara usa Fototeca sin llamar APIs exclusivas de captura.

El generador del proyecto usa identificadores deterministas. Regenerarlo dos veces produce exactamente los mismos archivos, de modo que una versión futura no reescribe el proyecto completo por UUID aleatorios.

### Recuperación sin score opaco

Caltrack lee sueño, frecuencia cardiaca en reposo y HRV SDNN desde Apple Salud solo después del permiso en contexto. Las muestra como tendencias personales junto a dieta, cuerpo y entrenamiento, sin convertirlas en una orden para entrenar o descansar y sin aplicar umbrales clínicos universales.

El cálculo cuenta solo intervalos dormidos, une solapamientos, atribuye la noche al día de despertar y conserva una fuente por noche. Esto evita sumar tiempo en cama junto a las fases o duplicar una noche registrada por varias aplicaciones. La caché diaria es local, restaurable desde la copia JSON y compatible con copias anteriores que no contienen recuperación.

### Plan adaptativo bajo control

El rango deja de ser un número manual sin seguimiento, pero Caltrack no se convierte en un piloto automático. Solo revisa días marcados como completos y exige siete cierres, tres pesos repartidos durante siete días y al menos 70% de adherencia al rango vigente. La tendencia usa regresión lineal sobre 14 días para reducir el efecto de una medición aislada.

Una propuesta mueve ambos límites 100 kcal, se limita entre 1.000 y 6.000 kcal y requiere confirmación explícita con comparación anterior y nueva. Después espera seis días. No calcula metabolismo con sexo, edad o altura, ni promete un ritmo de cambio. Hambre y energía sirven como contexto agregado y permanecen locales salvo que el usuario pregunte voluntariamente a Grok.

## 2026-07-13

### Estado diario visible sin abrir la app

Caltrack añade widgets pequeño y mediano para la pantalla de inicio y formatos inline, circular y rectangular para la pantalla de bloqueo. La prioridad es ver el progreso y llegar a Foto, Código o Peso con menos pasos. No se añade un widget grande porque repetiría el dashboard, ni una Live Activity porque el seguimiento nutricional dura todo el día y no necesita actualizaciones continuas.

### Snapshot mínimo en App Group

La extensión no abre SwiftData. La app calcula un `WidgetSnapshot` con las métricas estrictamente necesarias y lo guarda en `group.com.manuelsampedro.caltrack`. Esto evita compartir fotos, historial, HealthKit o Keychain con otro proceso. Un snapshot de otro día reinicia el consumo sin perder objetivos y WidgetKit solo recibe una solicitud de recarga cuando el contenido cambia.

### Privacidad y acciones en WidgetKit

Los valores, el recuento de comidas y el estado del plan se marcan como sensibles. En redacción privada el progreso se neutraliza para que el anillo no revele el consumo. Los botones reutilizan los App Intents existentes y escriben una ruta de un solo uso en el mismo App Group, sin añadir backend, SDK o API.

### Corrección por ingrediente antes y después de guardar

La estimación de una foto deja de ser una lista informativa. Cada componente detectado conserva nombre, porción, macros y fibra, y se puede corregir, añadir o borrar. El total se suma localmente en cada cambio y también admite una corrección final cuando el usuario conoce una cifra más precisa.

El mismo editor aparece abierto en el análisis fotográfico y mediante divulgación progresiva al editar una comida guardada. Esto mantiene una sola acción principal y evita una pantalla nueva. Los componentes se guardan como JSON Codable con almacenamiento externo dentro de `MealEntry`, una ampliación opcional y ligera que no introduce otra tabla ni una llamada adicional a Grok.

La copia JSON mantiene su versión actual y añade `components` como campo opcional. Las copias y bases anteriores se interpretan como comidas sin desglose. Una migración v1.8 a v1.9 en simulador confirmó que todos los registros previos permanecen intactos.

### Fibra sin falsa precisión

Caltrack añade fibra como valor opcional, no como cero por defecto. Una comida antigua, una etiqueta incompleta y un alimento con cero fibra son estados distintos. Hoy y Progreso suman lo conocido y muestran cuántas comidas tienen dato. El score no penaliza fibra incompleta.

La referencia inicial es 25 g al día, basada en la ingesta adecuada para adultos de EFSA, y se puede editar. Se presenta como referencia nutricional, no como prescripción. El color ámbar la separa de proteína, éxito y exceso sin crear otra pantalla.

Grok añade `fiber_g` a la misma salida estructurada. Open Food Facts aporta `fiber_100g` cuando existe. HealthKit recibe `dietaryFiber` si está autorizado. En una actualización, Caltrack pide el permiso nuevo al guardar en contexto; rechazar solo fibra no bloquea los cuatro nutrientes anteriores.

La base y el backup v1 conservan compatibilidad mediante campos opcionales. La migración v1.9 a v1.10 mantiene las comidas anteriores con fibra desconocida, sin reescribir su historia.

### Hevy sin pérdida silenciosa ni exceso de peticiones

La primera conexión recupera hasta diez páginas oficiales de diez entrenamientos, 100 sesiones en total. Las siguientes sincronizaciones consultan solo la primera página porque el historial ya está persistido y las sesiones se actualizan por su identificador estable. Cambiar o eliminar la clave reinicia la carga inicial.

El cliente respeta `page_count`, elimina IDs repetidos entre páginas y conserva compatibilidad con respuestas sin metadatos. Si la cuenta tiene más de 100 sesiones, la app lo dice en lugar de sugerir que importó todo. No se añade un proceso de fondo, servidor ni acceso directo a Strava.

### Release reproducible antes de TestFlight

Caltrack no se archiva desde un árbol sucio. El script de release exige un commit limpio, comprueba que la build solicitada coincide con el proyecto y genera un manifiesto con SHA del commit y checksum del IPA. Las claves de App Store Connect siguen fuera del repo.

La creación de la ficha y la subida quedan separadas. Así se puede verificar el artefacto completo sin usar una credencial filtrada ni fingir que una build local ya está distribuida.
