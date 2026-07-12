# Implementación de foto, Grok y Salud

## Objetivo

Construir un cliente iOS Caltrack local-first que replique el flujo fotográfico del tuit, lea medidas de Salud y no necesite VPS.

## Prerrequisitos

- Xcode 26.5 disponible.
- Identidad Apple Development válida.
- Clave de xAI para la prueba real.
- iPhone conectado para probar HealthKit con datos reales.

## Fases

### Fase 1: Base iOS y sistema visual

- Crear proyecto iOS 17+ con SwiftUI y SwiftData.
- Reproducir el dashboard, objetivos, barras y lista diaria.
- Añadir datos de preview y estados vacíos.

Éxito: build limpio y dashboard correcto en un iPhone simulado.

### Fase 2: Registro por foto

- Capturar desde cámara o fototeca.
- Redimensionar y comprimir antes de enviar.
- Añadir cliente xAI Responses API con Structured Outputs.
- Mostrar confirmación editable y guardar en SwiftData.
- Guardar la clave en Keychain.

Éxito: fixture de Grok decodifica, la corrección se guarda y la app maneja clave ausente y errores de red.

### Fase 3: Salud

- Añadir capability y descripciones de permisos.
- Pedir lectura de peso, grasa corporal y cintura.
- Consultar muestras recientes con HealthKit.
- Reflejar la última medida en el dashboard.

Éxito: build firmado y flujo de permiso verificable en dispositivo.

### Fase 4: Calidad y entrega

- Tests unitarios de decodificación y cálculos.
- Prueba visual en simulador, tamaños compactos y Reduce Motion.
- Documentar privacidad, configuración y límites de estimación.
- Instalar en el iPhone y probar una foto real cuando esté conectado y exista la clave.

Éxito: sin warnings propios, persistencia verificada y llamada real confirmada.
