# Plan de pulido nativo y conexiones

## Fase 1: Estado de conexiones

- [ ] Mostrar Salud, Hevy y Grok junto a la acción principal.
- [ ] Permitir iniciar Salud sin hacer scroll.
- [ ] Mostrar estados veraces y errores accionables.

## Fase 2: Configuración segura

- [ ] Validar la clave de Hevy contra la API antes de guardarla.
- [ ] Mantener claves solo en Keychain.
- [ ] Explicar que Grok necesita una clave de xAI y que OpenAI no es necesario.
- [ ] Actualizar la descripción de permiso de Salud.

## Fase 3: Jerarquía visual

- [ ] Simplificar el encabezado y la tarjeta de captura.
- [ ] Reducir ruido y tarjetas repetitivas.
- [ ] Aplicar estados, haptics, animaciones ligeras y accesibilidad.
- [ ] Aclarar en la PWA que Apple Salud requiere la app nativa.

## Fase 4: Verificación

- [ ] Probar la API real de Hevy sin registrar la clave en Git.
- [ ] Ejecutar tests unitarios y de interfaz.
- [ ] Ejecutar build limpio de simulador.
- [ ] Inspeccionar visualmente la app con datos reales de Hevy.
- [ ] Actualizar documentación y decisiones.
