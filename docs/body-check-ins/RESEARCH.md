# Check-ins corporales y fotos de progreso

## Visión general

Caltrack importa peso, grasa y cintura desde Apple Salud, pero algunas básculas no escriben todas las métricas y una medición manual no se puede registrar en la app nativa. Tampoco existe una forma privada de comparar fotos de progreso. El objetivo es cubrir ese hueco sin cuenta, backend ni una nueva API.

## Problema

- Salud puede contener peso y no contener cintura o grasa corporal.
- El usuario necesita registrar una medición aunque el iPhone no esté conectado o Salud no esté autorizada.
- Las fotos de progreso quedan dispersas en Fotos y no están relacionadas con peso y cintura.
- Una foto original puede ocupar demasiado espacio en SwiftData y en la copia JSON.

## Casos de uso

1. Registrar peso, grasa y cintura en menos de 20 segundos.
2. Añadir una foto opcional elegida mediante el selector privado del sistema.
3. Corregir o eliminar únicamente los check-ins manuales.
4. Ver la foto junto a la fecha y las métricas de ese momento.
5. Recuperar fotos y mediciones mediante la copia privada existente.

## Opciones técnicas

### Guardar rutas a Fotos

Reduce el tamaño local, pero la referencia puede dejar de funcionar y complica la copia. También exige conservar permisos y activos externos.

### Guardar la imagen original

Es simple, pero hace crecer la base y el JSON sin control.

### PhotosPicker, compresión local y SwiftData

El selector de Apple concede acceso solo al elemento elegido. La imagen se redimensiona localmente a un máximo de 1600 píxeles y se guarda como JPEG junto a `BodyMeasurement` usando almacenamiento externo. La copia privada incluye esos bytes.

## Recomendación

Usar `PhotosPicker` con selección única y sin solicitar acceso general a la fototeca. Comprimir antes de persistir, no subir la foto y no analizarla con IA. Los campos son opcionales, pero el check-in exige al menos una métrica o una foto.

## Datos

Ampliar `BodyMeasurement` con `photoData: Data?`. Mantener el formato de backup versión 1 con un campo opcional para conservar compatibilidad con copias antiguas.

Los check-ins usan `source = manual`. Las muestras de Salud siguen siendo de solo lectura y no se mezclan ni borran al editar un check-in.

## Diseño

Referencias:

1. Apple Fitness: una lectura principal, tendencia y evidencia visual sin saturar la pantalla.
2. PhotosPicker de Apple: selección explícita, privada y recuperable.
3. Caltrack actual: tarjetas carbón, verde para acción, azul para composición y coral para errores.

La tarjeta de composición incorpora una acción `Check-in`, un resumen de fotos y una lista breve de registros manuales. El formulario usa sheet grande, DatePicker, campos numéricos, preview, haptic de confirmación y copy claro sobre privacidad. La galería usa pantalla completa y mantiene las métricas visibles.

## Riesgos

- Tamaño: redimensionar y comprimir antes de guardar.
- Backup grande: mostrar que las fotos se incluyen y evitar originales de alta resolución.
- Datos sensibles: mantener todo local y no enviarlo a Grok ni Open Food Facts.
- Migración: el campo nuevo debe ser opcional y probarse sobre un almacén anterior.
- Duplicados: editar el check-in manual de ese día cuando corresponda y no tocar muestras de Salud.

## Referencias

- [PhotosPicker](https://developer.apple.com/documentation/photosui/photospicker)
- [Ejemplo de PhotosPicker y Transferable](https://developer.apple.com/documentation/PhotoKit/bringing-photos-picker-to-your-swiftui-app)
- [Privacidad en interfaces Apple](https://developer.apple.com/design/human-interface-guidelines/privacy)
- [SwiftData externalStorage](https://developer.apple.com/documentation/swiftdata/schema/attribute/option/externalstorage)
