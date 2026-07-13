# Investigación de calidad nutricional y fibra

## Problema

Caltrack registra calorías, proteína, carbohidratos y grasa, pero no conserva fibra. Esto impide distinguir una dieta que cumple energía y proteína de otra con poca fruta, verdura, legumbres o cereal integral. La fibra debe ayudar a decidir qué falta hoy, sin crear un score clínico ni convertir datos desconocidos en cero.

## Uso esperado

- Una foto analizada por Grok devuelve fibra estimada por componente y total.
- Un producto conserva la fibra declarada por Open Food Facts cuando existe.
- Una entrada manual admite fibra opcional.
- Hoy muestra avance contra un objetivo editable.
- Progreso muestra la tendencia y cuántas comidas contienen el dato.
- El entrenador local y Grok reciben fibra con su cobertura explícita.
- Apple Salud recibe fibra solo cuando la comida tiene un valor confirmado.

## Fuentes y plataforma

- EFSA considera 25 g al día una ingesta adecuada para adultos. Se usa como valor inicial editable, no como prescripción personal.
- HealthKit expone `dietaryFiber`, por lo que puede formar parte de la correlación de comida ya existente.
- Open Food Facts entrega nutrientes en `nutriments`, incluido `fiber_100g` cuando la etiqueta lo contiene.
- xAI ya devuelve salida estructurada estricta. Añadir `fiber_g` al esquema evita otra petición.

## Opciones técnicas

### Guardar cero

Es simple, pero falsea comidas antiguas y productos sin fibra declarada. Rechazado.

### Guardar un valor opcional

`MealEntry.fiber` es opcional. Los totales suman valores conocidos y conservan el número de comidas cubiertas. Es compatible con la base actual y permite decir `3 de 4 comidas con dato`.

### Tabla separada de nutrientes

Permitiría muchos micronutrientes, pero añade relaciones y edición genérica antes de validar su utilidad. Rechazado para esta fase.

## Recomendación

Añadir fibra opcional de extremo a extremo. Los componentes mantienen fibra opcional. El total solo se recalcula como completo cuando todos los componentes tienen dato. Los insights no reducen la puntuación por fibra desconocida.

## Pase de diseño

- Referencias: Caltrack actual, gauges y barras de progreso de Apple, gráficas de Salud de Apple.
- Paleta: carbón existente, verde para acción, azul para proteína, ámbar para fibra y coral solo para errores.
- Tipografía: sistema; números con `monospacedDigit`.
- Espaciado: 8, 12, 14 y 18 puntos.
- Iconos: `leaf.fill`, `fork.knife` y SF Symbols existentes.
- Estados: objetivo alcanzado, en progreso, parcial, desconocido y legacy.
- Haptics: se reutilizan los de guardar y editar, sin vibración por cada cambio numérico.
- Motion: progreso animable por SwiftUI y compatible con Reduce Motion.

## Privacidad y seguridad

No hay otra API ni más transferencia de datos. La fibra de una foto viaja en la misma petición voluntaria a xAI. Salud solo recibe el valor confirmado y autorizado. La copia privada incluye el dato, pero nunca claves.

## Riesgos

- Una foto estima fibra con margen de error. La UI debe mantener el aviso y edición.
- Open Food Facts puede omitirla. El campo queda vacío, no en cero.
- Bases y copias anteriores no contienen fibra. La migración debe validarse con v1.9 real.
- Un objetivo universal no sustituye consejo sanitario. El valor es editable y se presenta como referencia.

## Referencias

- Apple HealthKit `dietaryFiber`: https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/dietaryfiber
- Apple HIG Gauges: https://developer.apple.com/design/human-interface-guidelines/gauges
- Apple HIG Charts: https://developer.apple.com/design/human-interface-guidelines/charts
- EFSA, Dietary Reference Values for carbohydrates and dietary fibre: https://efsa.onlinelibrary.wiley.com/doi/10.2903/j.efsa.2010.1462
- Open Food Facts API: https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/
