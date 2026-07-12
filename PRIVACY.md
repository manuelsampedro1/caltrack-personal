# Privacidad de Caltrack

Caltrack es una herramienta personal y local-first.

## Datos guardados en el dispositivo

La app iOS guarda comidas, macros, fotos confirmadas de platos, check-ins corporales, fotos de progreso opcionales, medidas y entrenamientos importados en el almacenamiento local del iPhone. Las claves de xAI y Hevy se guardan en Keychain con acceso limitado al dispositivo.

La PWA guarda sus datos por separado en IndexedDB dentro del navegador.

## Fotos y xAI

Una foto se envía a la API de xAI únicamente cuando el usuario decide analizarla. La petición solicita a xAI que no conserve historial mediante `store: false`. Caltrack no usa un servidor propio y no envía datos de Apple Salud junto con la foto.

El entrenador funciona localmente por defecto. Solo cuando el usuario envía una pregunta, Caltrack manda a xAI un resumen limitado de hasta 30 días con totales nutricionales, medidas y actividad. No incluye fotos, claves, identificadores de muestras o identificadores de aplicaciones de Salud. La conversación se guarda localmente.

## Fotos de progreso

Una foto de progreso solo se obtiene después de que el usuario la elige mediante PhotosPicker. Caltrack no solicita acceso general a la fototeca. La imagen se redimensiona y comprime en el iPhone, se guarda junto al check-in manual y nunca se envía a xAI, Open Food Facts, Hevy ni otro servicio.

Las fotos de progreso forman parte de la copia JSON privada porque son necesarias para restaurar el historial completo. El archivo exportado queda bajo control del usuario y puede ser considerablemente mayor cuando contiene fotos.

## Códigos de barras y Open Food Facts

Cuando el usuario escanea o busca un producto, Caltrack envía únicamente el número del código de barras a `world.openfoodfacts.org`. No envía la foto de la cámara, datos de Apple Salud, entrenamientos, comidas anteriores ni claves.

La consulta no requiere una cuenta y el producto solo se guarda después de revisar y confirmar sus datos. Open Food Facts es una base colaborativa sujeta a sus propias condiciones y licencia ODbL. Los valores pueden ser incompletos o incorrectos y permanecen editables en Caltrack.

## Apple Salud

Caltrack solicita acceso de lectura a:

- peso
- porcentaje de grasa corporal
- circunferencia de cintura
- entrenamientos, energía activa y distancia
- energía basal y pasos

El usuario elige qué permisos concede y puede cambiarlos en Salud o Ajustes. Caltrack no vende, comparte ni usa estos datos para publicidad.

De forma separada y desactivada por defecto, el usuario puede permitir que Caltrack escriba las comidas que confirma. Cada comida se guarda como una correlación de Salud con:

- energía dietética
- proteína
- carbohidratos
- grasa total

Caltrack no solicita lectura de nutrición ni importa comidas creadas por otras aplicaciones. Editar o borrar una comida actualiza o elimina el registro creado por Caltrack mientras la opción está activa. Desactivar la opción detiene escrituras futuras y no borra silenciosamente el historial ya guardado en Salud. La sincronización de comidas anteriores requiere pulsar un botón explícito.

## Hevy y Strava

Caltrack puede leer desde Salud los resúmenes de entrenamientos creados por Strava, Hevy u otras aplicaciones autorizadas. Si el usuario facilita voluntariamente una clave de Hevy Pro, Caltrack consulta directamente `api.hevyapp.com` para añadir ejercicios, series, repeticiones, cargas y RPE.

Caltrack no solicita credenciales de Strava. Strava comparte sus actividades con Salud cuando el usuario activa esa opción dentro de Strava.

## Copias y recordatorios

La exportación JSON puede contener comidas, fotos de platos, fotos de progreso, medidas, actividad, entrenamientos y conversación. Las claves de Keychain nunca se exportan. El archivo queda bajo control del usuario en el selector de documentos de iOS.

Los recordatorios son notificaciones locales programadas por el propio iPhone. No se usa servidor, publicidad ni seguimiento.

## Límites

Los cálculos nutricionales obtenidos desde una foto y los datos recuperados por código de barras deben revisarse antes de guardarse. No sustituyen consejo médico o nutricional.
