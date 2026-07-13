# Investigación de distribución por TestFlight

## Objetivo

Instalar Caltrack en el iPhone sin depender de que el dispositivo esté conectado al Mac y conservar un camino de release reproducible.

## Estado comprobado

- Repositorio en `main`, limpio y sincronizado.
- Bundle principal `com.manuelsampedro.caltrack` y widget registrados en Apple Developer.
- Certificado Apple Distribution válido.
- App y widget firman con HealthKit y App Group.
- Credencial activa de App Store Connect disponible fuera del repositorio.
- No existía una ficha de Caltrack en App Store Connect.
- La credencial activa puede leer y subir builds, pero no tiene permiso para crear una app.

## Requisitos de Apple

Apple exige crear la ficha antes de subir la primera build. La ficha necesita plataforma, nombre, idioma principal, bundle ID y SKU. Después se puede subir el IPA y esperar su procesamiento antes de añadirlo a un grupo interno.

Fuentes:

- <https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/>
- <https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/>
- <https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/>

## Enfoque

- Crear un script local que archive, exporte, valide y opcionalmente suba.
- Exigir repositorio limpio y número de build coincidente.
- Usar solo variables `ASC_*` y claves externas al repo.
- Generar manifiesto con commit, versión, build y SHA-256 del IPA.
- No subir hasta que exista la ficha y haya una credencial no filtrada con permisos suficientes.

## Incidente de credencial

Una traza de Fastlane mostró material privado de una clave secundaria. Esa clave queda fuera de uso y debe revocarse. La credencial activa usada por Xcode es otra y no apareció en la traza.

## Privacidad y export compliance

Apple exige motivos aprobados para `UserDefaults` desde mayo de 2024. Caltrack usa preferencias privadas y un App Group, por lo que declara `CA92.1` y `1C8F.1`. También declara de forma conservadora foto, contenido, salud y fitness porque una pregunta voluntaria a xAI puede incluir esos datos.

Caltrack no implementa cifrado propio. HTTPS y Keychain son APIs de Apple, por lo que la build declara `ITSAppUsesNonExemptEncryption` en `NO`.

Fuentes:

- <https://developer.apple.com/documentation/bundleresources/privacy-manifest-files>
- <https://developer.apple.com/documentation/BundleResources/Information-Property-List/ITSAppUsesNonExemptEncryption>
