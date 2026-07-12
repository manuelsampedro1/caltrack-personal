# Privacidad de Caltrack

Caltrack es una herramienta personal y local-first.

## Datos guardados en el dispositivo

La app iOS guarda comidas, macros, fotos confirmadas y medidas importadas en el almacenamiento local del iPhone. La clave de xAI se guarda en Keychain con acceso limitado al dispositivo.

La PWA guarda sus datos por separado en IndexedDB dentro del navegador.

## Fotos y xAI

Una foto se envía a la API de xAI únicamente cuando el usuario decide analizarla. La petición solicita a xAI que no conserve historial mediante `store: false`. Caltrack no usa un servidor propio y no envía datos de Apple Salud junto con la foto.

## Apple Salud

Caltrack solicita acceso de lectura únicamente a:

- peso
- porcentaje de grasa corporal
- circunferencia de cintura

El usuario elige qué permisos concede y puede cambiarlos en Salud o Ajustes. Caltrack no vende, comparte ni usa estos datos para publicidad.

## Límites

Los cálculos nutricionales obtenidos desde una foto son estimaciones. Deben revisarse antes de guardarse y no sustituyen consejo médico o nutricional.
