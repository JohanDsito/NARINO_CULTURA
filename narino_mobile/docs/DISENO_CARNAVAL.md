# Guía de diseño "Carnaval" — App móvil Nariño Cultura

Base: `narino_cultura_movil_1_design_system.html` y `narino_cultura_movil_2_inicio.html`.
Código: `lib/core/theme/` (`app_colors.dart`, `nc_theme.dart`, `app_typography.dart`, `app_theme.dart`)
y `lib/shared/widgets/design/`.

## 1. Idea

El fondo celebra la fiesta (orbes, sol, nota, lente, talco); la interfaz encima es
limpia y deja que la obra sea protagonista. Colores **puros y vibrantes**, nada de pasteles:
cuando hace falta un tono suave se usa el mismo color con transparencia.

## 2. Paleta base

| Rol | Oscuro (por defecto) | Claro |
|---|---|---|
| Fondo | `#050505` | `#F5F5F7` |
| Tarjeta | `#121214` | `#FFFFFF` |
| Vidrio (header/tabbar) | `rgba(18,18,20,.72)` | `rgba(255,255,255,.78)` |
| Texto principal | `#F5F5F7` | `#1D1D1F` |
| Texto secundario | `#86868B` (5.2:1) | `#6E6E73` (4.7:1) |
| Texto tenue | `#7C7C82` (4.5:1) | `#74747A` (4.6:1) |
| Borde | `rgba(255,255,255,.08)` | `rgba(0,0,0,.06)` |

## 3. Acentos: cada color tiene 4 usos

Los neón puros **no se leen como texto sobre fondo claro** (2.1–3.7:1). Por eso cada acento
tiene una "tinta" para texto que en claro es más oscura. Contraste medido sobre `#F5F5F7`.

| Acento | Relleno (`fill`) | Texto encima (`onFill`) | Tinta oscuro | Tinta claro | Tinte (`tint`) |
|---|---|---|---|---|---|
| Azul (acción) | `#00E5FF` / `#0055FF` | negro / blanco | `#00E5FF` | `#0055FF` (5.2:1) | 14 % / 10 % |
| Tomate | `#FF3300` | negro (5.7:1) | `#FF3300` | `#C82800` (5.1:1) | 16 % / 10 % |
| Naranja | `#FF6600` | negro (7.2:1) | `#FF6600` | `#B34700` (5.1:1) | 16 % / 10 % |
| Oro | `#D4AF37` | negro (10:1) | `#D4AF37` | `#8A6400` (4.9:1) | 16 % / 12 % |
| Magenta | `#E50050` | blanco (4.7:1) | `#FF0055` | `#C8004A` (5.4:1) | 16 % / 10 % |
| Verde (éxito) | `#00C46A` | negro (9.1:1) | `#00C46A` | `#007A47` (5.0:1) | 16 % / 10 % |

En código: `context.nc.naranjaA.fill / .onFill / .ink / .tint`.

**Reglas de uso**
- Texto de color → siempre `ink`.
- Botón, chip activo o insignia → `fill` con `onFill` (letras negras sobre neón cálido, como las carrozas).
- Fondo de estado o selección → `tint` + borde `fill` al 45 %.
- Los neón puros se usan libres en decoración (orbes, serpentina, bordes, puntos).

## 4. Color por sección

| Sección | Acento | Por qué |
|---|---|---|
| Acción principal (todas) | **Azul** | Consistencia: un solo color para "hacer algo" |
| Catálogo / artes plásticas | **Magenta** | Definido así en el design system |
| Tienda / artesanos | **Naranja** | Ídem |
| Subastas | **Oro** (premium) + **tomate** para "en vivo" / cuenta regresiva | Valor + urgencia |
| Eventos / agenda | **Tomate** (la hora va en naranja) | Energía de fiesta |
| Música | **Azul** | Ídem |
| Perfil / comunidad | **Serpentina** completa | Identidad de cada persona |
| Estados | Verde éxito · tomate error · oro aviso | |

En código: `nc.catalogo`, `nc.tienda`, `nc.subastas`, `nc.enVivo`, `nc.eventos`, `nc.musica`.

## 5. Degradados

| Nombre | Colores | Uso |
|---|---|---|
| `borderGradient` | azul → naranja | Borde de tarjetas en oscuro (del diseño) |
| `brandGradient` | naranja → magenta | Logo "N" |
| `carnavalGradient` (serpentina) | tomate → naranja → oro → magenta → azul | Franjas, anillos de avatar, detalles. **Nunca detrás de texto** |
| `fiestaGradient` | tomate → magenta | Héroes y banners con texto blanco grande |
| `titleGradient` | blanco → azul | Títulos grandes en oscuro |

## 6. Cómo se siente cada modo

**Oscuro (noche de carnaval):** fondo casi negro, orbes al 45 %, tarjetas con borde neón
degradado y sombra profunda, botón azul con brillo, títulos con degradado.

**Claro (día de desfile):** fondo gris perla, orbes al 28 %, tarjetas blancas con borde sutil
(sin degradado), sin brillos; el color entra por los acentos (chips, íconos, insignias)
y por tintes suaves. Textos de color siempre con su tinta oscura.

## 7. Componentes

| Componente | Archivo | Notas |
|---|---|---|
| Fondo carnaval | `carnaval_background.dart` | Parallax con el scroll; respeta "reducir movimiento" |
| Tarjeta | `nc_card.dart` → `NcCard` | Radio 22, borde degradado en oscuro |
| Header vidrio / marca / botón redondo | `nc_header.dart` | Botón 44 px con contador |
| Barra inferior | `nc_tab_bar.dart` | 64 px, activa en azul |
| Botones | `nc_buttons.dart` → `NcPrimaryButton`, `NcSecondaryButton` | Píldora 50 px, estado cargando |
| Avisos | `NcBanner.error / .success` | Tinte + borde del acento |
| Ícono con acento | `NcAccentIcon` | Círculo teñido |
| Serpentina | `NcSerpentina` | Franja con el degradado carnaval |
| Ítem de agenda | `nc_event_item.dart` | Hora en naranja (tinta) |
| Reacción al toque | `NcPressable` | Escala 0.96 con curva "spring" |

## 8. Accesibilidad

- Contraste de texto ≥ 4.5:1 en ambos modos (ver tabla 3).
- Áreas táctiles ≥ 44 px.
- `Semantics` en botones de ícono, días del calendario, opciones seleccionables y avisos (`liveRegion`).
- Animaciones desactivadas si el sistema pide reducir movimiento.

## 9. Revisión visual

`test/_preview/*_preview_test.dart` genera capturas PNG claro/oscuro con la fuente real:

```
flutter test test/_preview --dart-define=OUT=<carpeta> \
  --dart-define=FONTS=<carpeta con Inter-300..800.ttf> \
  --dart-define=ICONS=<flutter>/bin/cache/artifacts/material_fonts/materialicons-regular.otf
```

En la suite normal se saltan. En las capturas de prueba los emojis salen como cuadro
y las sombras de elevación como borde sólido; en el teléfono se ven bien.
