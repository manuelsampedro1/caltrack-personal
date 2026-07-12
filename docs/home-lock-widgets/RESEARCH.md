# Widgets de inicio y bloqueo

## Problema

Caltrack ya resuelve registro, Salud, Hevy, progreso y revisión semanal. El hueco diario es que toda esa utilidad empieza después de abrir la app. Para saber cómo va el día o fotografiar una comida hay que localizar el icono, abrir Caltrack y volver a buscar la acción.

El widget debe convertir Caltrack en una presencia útil y discreta: estado de hoy a simple vista y acceso inmediato a foto, código o check-in, sin servidor y sin exponer el historial completo a una extensión.

## Casos de uso

- Ver calorías y proteína del día sin abrir la app.
- Saber si el día está cerrado y leer el estado del plan.
- Abrir directamente la cámara o el escáner desde un widget mediano.
- Consultar una síntesis en la pantalla de bloqueo o StandBy.
- Ocultar los valores cuando el sistema aplica protección de privacidad.
- Mostrar un estado honesto si Caltrack todavía no ha generado datos para hoy.

## Opciones técnicas

### Abrir SwiftData directamente desde la extensión

Permite consultar cualquier registro, pero obliga a mover la base a un App Group y aumenta el riesgo de migración, acceso simultáneo y acoplamiento entre procesos. El widget no necesita todo el historial.

### Copiar un snapshot mínimo a UserDefaults compartido

La app calcula el estado con sus modelos actuales y guarda solo los valores que el widget muestra. La extensión lee un objeto pequeño, no abre SwiftData, no usa HealthKit, no accede a Keychain y no hace red.

Esta es la opción recomendada. Usa un App Group porque Apple lo define como el mecanismo para compartir datos limitados entre una app y su extensión. La app pide una recarga a WidgetKit solo cuando cambia el snapshot.

### Live Activity

Una Live Activity encaja con una tarea acotada que cambia con frecuencia. El seguimiento nutricional dura todo el día y cambia pocas veces, por lo que un widget es más honesto y consume menos. Se deja fuera de esta fase.

## Diseño

Referencias:

1. Human Interface Guidelines de widgets: información esencial, legible y útil, no una miniatura de la app.
2. Widgets de Fitness y Salud: métricas principales, anillos o barras y jerarquía inmediata.
3. Lenguaje existente de Caltrack: carbón, verde para progreso, azul para proteína, coral solo para exceso y SF Symbols.

Sistema visual:

- fondo carbón sin adornos ni fotografías
- tipografía del sistema, números monoespaciados para métricas
- verde para calorías y cierre, azul para proteína
- barras de 4 a 6 puntos y radios de 12 a 18 puntos
- acciones con `camera.fill`, `barcode.viewfinder` y `scalemass.fill`
- estados vacíos concretos, sin datos simulados
- contenido nutricional marcado como privado para que iOS pueda ocultarlo al bloquear

Familias:

- `systemSmall`: progreso del día y dos acciones rápidas.
- `systemMedium`: métricas, estado del plan y tres acciones.
- `accessoryRectangular`: calorías, proteína y cierre.
- `accessoryCircular`: porcentaje calórico del día.
- `accessoryInline`: síntesis de calorías y proteína.

No se añade un widget grande. Repetiría el dashboard y reduciría la claridad.

## Arquitectura

`WidgetSnapshot` contiene únicamente:

- día al que pertenecen los datos
- fecha de generación
- calorías y proteína consumidas
- límites calóricos y proteína mínima
- número de comidas
- estado de cierre del día
- título breve del plan adaptativo

`WidgetSnapshotStore` codifica el objeto en `UserDefaults` del App Group `group.com.manuelsampedro.caltrack`. Si el snapshot pertenece a otro día, conserva objetivos pero reinicia el consumo para no mostrar ayer como si fuera hoy.

La app actualiza el snapshot cuando cambian comidas, objetivos o cierre. Después llama a `WidgetCenter.reloadTimelines`. La extensión usa una timeline amplia y no hace red.

Los App Intents actuales se comparten con la extensión. `QuickActionStore` pasa a usar el mismo App Group para que una acción iniciada desde el widget llegue al proceso principal.

## Privacidad y seguridad

- El widget no recibe fotos, historial, identificadores de Salud, claves de xAI o Hevy.
- Los valores se marcan con `privacySensitive()`.
- El placeholder usa datos ficticios y redacción.
- La extensión no solicita HealthKit ni cámara.
- La clave de Hevy expuesta anteriormente sigue fuera del repositorio y debe regenerarse.

## Producto y distribución

El widget mejora el value moment antes de abrir la app y crea una captura de App Store clara: progreso real más acceso a foto. No se convierte en una función premium en esta app personal. Si Caltrack se comercializa, puede formar parte del argumento de retención sin bloquear el registro básico.

## Riesgos

- App Groups necesita una sesión Apple Developer válida para registrar y firmar el identificador en un iPhone real.
- WidgetKit decide cuándo renderizar y limita recargas. La app debe preparar los datos y no depender de ejecución continua.
- Los widgets con contenido sensible pueden aparecer en pantalla de bloqueo. La redacción es obligatoria.

## Referencias

- [Widgets en Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/widgets)
- [Crear una extensión WidgetKit](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension)
- [Mantener un widget actualizado](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)
- [Configurar App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [Estrategia de WidgetKit y privacidad](https://developer.apple.com/documentation/widgetkit/developing-a-widgetkit-strategy)
