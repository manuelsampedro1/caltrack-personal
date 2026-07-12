# Acceso rápido con Atajos y Siri

## Visión general

Caltrack ya permite fotografiar comida, escanear un producto, crear un check-in y revisar progreso, pero cada acción exige abrir la app y navegar. En una herramienta diaria, esos segundos repetidos reducen la constancia. App Intents puede exponer las acciones principales a Siri, Spotlight, Atajos y el botón Acción sin backend ni permisos nuevos.

## Problema

- La cámara y el código de barras están dentro de la tab Hoy.
- El check-in corporal está dentro de Progreso.
- El sistema no sabe qué acciones ofrece Caltrack.
- El usuario no puede poner una captura directa en el botón Acción o en una automatización.

## Casos de uso

1. Decir `Fotografiar comida con Caltrack` y llegar directamente a la cámara.
2. Ejecutar `Escanear producto` desde Spotlight o el botón Acción.
3. Abrir un nuevo check-in sin navegar por Progreso.
4. Abrir la tab Progreso desde Siri o Atajos.
5. Consultar todos los atajos disponibles desde Ajustes.

## Opciones técnicas

### Enlaces universales

Son adecuados para contenido web, pero requieren dominio, asociación y configuración adicional. No aportan valor para rutas privadas de una app personal.

### Esquema URL personalizado

Permite rutas internas, pero el sistema no descubre las acciones ni genera frases de Siri automáticamente.

### App Intents y App Shortcuts

Expone acciones nativas a Siri, Spotlight, Atajos y hardware. La intención deja una ruta pendiente local y abre la app. RootView consume la ruta y activa la tab o presentación adecuada.

## Recomendación

Crear cuatro intents sin parámetros, ordenados por frecuencia:

1. Fotografiar comida.
2. Escanear producto.
3. Nuevo check-in.
4. Abrir progreso.

Apple recomienda ofrecer entre dos y cinco acciones realmente comunes. Las frases serán breves, en español e incluirán el nombre de Caltrack.

## Arquitectura

- `QuickAction`: enum local con las cuatro rutas.
- `QuickActionStore`: almacena una única ruta pendiente en UserDefaults y la consume una vez.
- `CaltrackShortcuts`: proveedor de App Shortcuts.
- `RootView`: decide la tab y envía una solicitud de presentación a la vista hija.
- `DashboardView` y `ProgressDashboardView`: consumen bindings de un solo uso.
- `SettingsView`: muestra acciones disponibles y `ShortcutsLink` para abrir la página de Caltrack en Atajos.

No se guarda información nutricional, corporal ni de Salud en el intent. Solo se persiste temporalmente el nombre de una ruta.

## Diseño

Referencias:

1. App Shortcuts de Apple: pocas acciones, verbos claros y SF Symbols familiares.
2. Atajos: botón nativo `ShortcutsLink` y frases fáciles de recordar.
3. Caltrack: verde para acciones, carbón para superficie y copy directo.

La integración no añade otra tarjeta a Hoy. Vive en Ajustes y en las superficies del sistema, con una lista compacta de las cuatro acciones y un único botón para abrir Atajos.

## Riesgos

- Ruta perdida al abrir la app: conservarla hasta que onboarding y presentaciones permitan consumirla.
- Repetición: consumir y borrar la ruta una sola vez.
- Estado en segundo plano: observar activación de escena y entregar cambios de UserDefaults en el hilo principal.
- APIs recientes: mantener compatibilidad con iOS 17 y usar el modo de primer plano moderno cuando esté disponible.
- Cámara en simulador: probar rutas de código y check-in, y verificar la intención de cámara a nivel unitario.

## Referencias

- [App Intents](https://developer.apple.com/documentation/appintents/app-intents)
- [Acelerar interacciones con App Intents](https://developer.apple.com/documentation/appintents/acceleratingappinteractionswithappintents)
- [App Shortcuts](https://developer.apple.com/design/human-interface-guidelines/app-shortcuts)
- [ShortcutsLink](https://developer.apple.com/documentation/appintents/shortcutslink)
- [Modos de ejecución](https://developer.apple.com/documentation/appintents/appintent/supportedmodes)
