# Design system "Carnaval" — Web

La web usa el mismo design system que la app móvil ([`narino_mobile/docs/DISENO_CARNAVAL.md`](../../narino_mobile/docs/DISENO_CARNAVAL.md)):
el fondo celebra la fiesta y la interfaz encima es limpia para que la obra sea protagonista.

- Tokens: `src/index.css` (variables CSS en `:root` y `.dark`)
- Clases de Tailwind: `tailwind.config.ts`
- Componentes: `src/components/ui/` y `src/components/layout/`

## Modo claro y oscuro

Si la persona no eligió un modo, la web **sigue el del sistema**. El botón de la barra guarda su elección.
`index.html` aplica el modo antes de dibujar, para que no haya destello al abrir en oscuro.

| Rol | Oscuro (noche de carnaval) | Claro (día de desfile) | Clase |
|---|---|---|---|
| Fondo | `#050505` | `#F5F5F7` | `bg-bg` (solo el `body`; las páginas no lo repiten para que se vean los orbes) |
| Tarjeta | `#121214` | `#FFFFFF` | `bg-bg-card` |
| Superficie suave | `#1C1C1F` | `#EBEBF0` | `bg-bg-subtle` |
| Texto | `#F5F5F7` / `#86868B` / `#7C7C82` | `#1D1D1F` / `#6E6E73` / `#74747A` | `text-text-primary` / `-secondary` / `-muted` |
| Borde | blanco 8 % | negro 8 % | `border-border` (también el `border` sin color) |
| Borde de campos | blanco 16 % | negro 16 % | `border-border-strong` |

## Acentos: cuatro usos por color

Los neón puros no se leen como texto sobre fondo claro. Por eso cada acento tiene una **tinta**, que en claro es más oscura y
pasa el contraste AA.

| Acento | Tinta (texto) | Relleno | Texto sobre el relleno | Tinte (fondo suave) |
|---|---|---|---|---|
| Azul (acción) | `text-azul` | `bg-azul-fill` | `text-on-azul` | `bg-azul-tint` |
| Tomate | `text-tomate` | `bg-tomate-fill` | `text-on-tomate` | `bg-tomate-tint` |
| Naranja | `text-naranja` | `bg-naranja-fill` | `text-on-naranja` | `bg-naranja-tint` |
| Oro | `text-oro` | `bg-oro-fill` | `text-on-oro` | `bg-oro-tint` |
| Magenta | `text-magenta` | `bg-magenta-fill` | `text-on-magenta` | `bg-magenta-tint` |
| Verde | `text-verde` | `bg-verde-fill` | `text-on-verde` | `bg-verde-tint` |

**Reglas**
- Texto de color: siempre la tinta (`text-x`). Nunca `text-x-fill`.
- Botón, chip activo o insignia sólida: `bg-x-fill` con `text-on-x`. **Nunca `text-white` fijo**: en oscuro el azul es
  cian y necesita letras negras.
- Fondo de estado o selección: `bg-x-tint` con borde `border-x/40`.
- Nada de colores sueltos (`#…`, `amber-*`, `gray-*`, `text-white`). La excepción son los colores de marca de las redes
  sociales al pasar el mouse.

**Alias anteriores.** Siguen funcionando para no romper pantallas, pero en código nuevo hay que usar los nombres nuevos.

| Alias | Equivale a |
|---|---|
| `tierra`, `tierra-pale`, `on-tierra` | `azul`, `azul-tint`, `on-azul` |
| `selva`, `selva-pale` | `verde`, `verde-tint` |
| `indigo`, `indigo-pale` | `magenta`, `magenta-tint` |
| `oro-pale` | `oro-tint` |
| `error`, `success` | `tomate`, `verde` |

## Color por sección

| Sección | Acento |
|---|---|
| Acción principal (todas) | **Azul** |
| Catálogo / artes plásticas | Magenta |
| Tienda / artesanos | Naranja |
| Subastas | Oro, y tomate para "en vivo" |
| Eventos / agenda | Tomate |
| Música | Azul |
| Estados | Verde éxito · tomate error · oro aviso |

Aplicado en la web:

- Precios en **naranja** en toda la web, como en la app.
- Cada página lleva su etiqueta de sección con `PageShell` y los títulos cambian al color de la sección al pasar el mouse.
- Estados de obra: «en subasta» en oro y «vendida» en neutro. Subasta «en curso» en tomate, con el punto en vivo.
- La hora de los eventos va en naranja.
- El inicio muestra las cuatro secciones con su color.

`PageShell` acepta `eyebrow` y `accent`: `<PageShell eyebrow="Artes plásticas" accent="magenta" title="Catálogo de Obras" />`.
`ArtworkImage` usa el tinte de la sección cuando la obra no tiene foto.

## Forma y tipografía

- Fuente **Inter** (300–800). Los títulos van en `font-extrabold` con espaciado −0.02em.
- Tarjetas: `rounded-card` (22 px). En oscuro, `Card` lleva borde degradado azul → naranja (clase `nc-card`).
- Botones: píldora (`rounded-btn`) de 44 px (`h-11`) y 36 px (`sm`), con reacción al toque (`active:scale-[0.96]`,
  `ease-spring`).
- Campos: `rounded-input` (14 px), fondo de tarjeta, `border-border-strong`, foco azul.

## Utilidades (`index.css`)

| Clase | Uso |
|---|---|
| `nc-card` | Borde degradado de tarjeta en oscuro |
| `nc-glass` | Barra y pie de vidrio (`backdrop-filter`) |
| `nc-eyebrow` | Etiqueta de sección en mayúsculas sobre los títulos |
| `nc-serpentina` | Franja tomate → naranja → oro → magenta → azul. **Nunca detrás de texto** |
| `nc-fiesta` | Degradado tomate → magenta para héroes con texto blanco grande |
| `nc-brand` | Degradado naranja → magenta del logo |

El fondo de orbes vive en `body::before`: va al 45 % en oscuro y al 28 % en claro. No se anima.

## Revisión visual

Antes de dar por terminada una pantalla, revisarla en claro y en oscuro, en escritorio (1280 px) y en celular (390 px).
