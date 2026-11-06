# Design System — Nariño Cultura

## 📋 Introducción

El Design System de Nariño Cultura proporciona una paleta de colores, tipografía y componentes consistentes para toda la aplicación.

**Características:**
- ✅ Modo claro y oscuro nativos
- ✅ Variables CSS sincronizadas con Tailwind
- ✅ Tipografía premium (Playfair Display, DM Sans, Cormorant Garamond)
- ✅ Componentes reutilizables con variantes
- ✅ Animaciones suaves (Framer Motion, Tailwind)
- ✅ Accesibilidad WCAG AA

---

## 🎨 Colores

### Modo Claro (Predeterminado)

```
--bg:               #F7F3EE   (Fondo principal — crema cálido)
--bg-card:          #FFFFFF   (Cards)
--bg-subtle:        #EDE8E1   (Inputs, hover suave)
--text-primary:     #1A1208   (Headings, nombres)
--text-secondary:   #5C4F3A   (Descripciones)
--text-muted:       #9C8E78   (Fechas, metadatos)
--border:           #DDD6CA   (Bordes)

-- TIERRA (primario)
--tierra:           #8B4513   (Botones, CTA)
--tierra-light:     #C1763A   (Hover botones)
--tierra-pale:      #F0DCC8   (Tags, hover superficial)

-- VOLCÁN (neutros profundos)
--volcan:           #2D1B00   (Header, navbar)
--volcan-mid:       #4A3320   (Secciones oscuras)

-- ORO ANDINO (acento premium)
--oro:              #C9921A   (Precios, subastas)
--oro-light:        #F0C060   (Texto sobre oscuro)
--oro-pale:         #FBF0D5   (Badges, alertas)

-- SELVA & ÍNDIGO (complementarios)
--selva:            #2E5E30   (Éxito, disponible)
--selva-light:      #5A9B5C   (Iconos éxito)
--selva-pale:       #D4EBD5
--indigo:           #3B3580   (Links, subastas)
--indigo-light:     #6B65C0   (Hover indigo)
--indigo-pale:      #E1E0F5

-- SEMÁNTICOS
--error:            #C0392B
--success:          #27AE60
```

### Modo Oscuro

En modo oscuro, las variables se invierten automáticamente al agregar la clase `.dark` al elemento `<html>`.

**Uso en componentes:**
```tsx
// Siempre usar variables CSS, NUNCA hardcodear colores
<div className="bg-tierra text-text-primary">
  Contenido
</div>
```

---

## 🔤 Tipografía

### Familias

| Rol       | Fuente                | Uso |
|-----------|----------------------|-----|
| Display   | Playfair Display 900  | Títulos hero, H1 |
| Heading   | Playfair Display 700  | H2, H3, nombres artistas |
| Accent    | Cormorant Garamond 300 italic | Subtítulos, citas |
| Body      | DM Sans 400/500       | Párrafos, texto UI |
| Label     | DM Sans 600/700       | Botones, badges, precios |
| Mono      | DM Sans               | Tags código, referencias |

### Escala de Tamaños

| Clase CSS    | Tamaño | Uso |
|--------------|--------|-----|
| `.text-display` | clamp(30px, 6vw, 50px) | Hero principal |
| `.text-h1`     | clamp(26px, 5vw, 42px) | Títulos principales |
| `.text-h2`     | 28px | Subtítulos secciones |
| `.text-h3`     | 21px | Subheadings |
| `.text-body`   | 15px | Párrafos, UI |
| `.text-small`  | 13px | Descripciones cortas |
| `.text-label`  | 11px | Badges, labels |
| `.text-micro`  | 10px | Metadatos |
| `.text-accent` | 18px italic | Subtítulos decorativos |

**Uso en componentes:**
```tsx
<h1 className="text-h1 font-display text-text-primary">
  Título Principal
</h1>

<p className="text-body font-body text-text-secondary">
  Descripción del contenido...
</p>

<span className="text-accent text-text-muted">
  "Tagline elegante"
</span>
```

---

## 🛠️ Componentes Base

### Button (3 variantes)

```tsx
// Primario (terra)
<button className="bg-tierra text-white hover:bg-tierra-light rounded-btn">
  Acción Principal
</button>

// Secundario (outline)
<button className="bg-transparent border border-tierra text-tierra hover:bg-tierra-pale rounded-btn">
  Acción Secundaria
</button>

// Gold (premium)
<button className="bg-oro text-volcan hover:bg-oro-light font-semibold rounded-btn">
  Precio / CTA Subasta
</button>
```

**Estilos base aplicados automáticamente:**
- Font: DM Sans 600, 13px
- Padding: 9px 18px
- Border-radius: 7px
- Transición: 0.35s smooth
- Hover: translateY(-1px)

### Badge / Tag (4 variantes)

```tsx
<span className="bg-tierra-pale text-tierra rounded-tag px-2.5 py-0.5 text-xs font-semibold">
  Tag Tierra
</span>

<span className="bg-oro-pale text-oro rounded-tag px-2.5 py-0.5 text-xs font-semibold">
  Tag Oro
</span>

<span className="bg-selva-pale text-selva rounded-tag px-2.5 py-0.5 text-xs font-semibold">
  Tag Selva (Disponible)
</span>

<span className="bg-indigo-pale text-indigo rounded-tag px-2.5 py-0.5 text-xs font-semibold">
  Tag Indigo
</span>
```

### Alert (3 variantes)

```tsx
<div className="bg-selva-pale text-selva border-l-4 border-selva p-3 rounded-lg">
  ✓ Acción completada exitosamente
</div>

<div className="bg-oro-pale text-oro border-l-4 border-oro p-3 rounded-lg">
  ⚠ Advertencia importante
</div>

<div className="bg-red-100 text-error border-l-4 border-error p-3 rounded-lg">
  ✕ Ocurrió un error
</div>
```

### Card

```tsx
<div className="bg-bg-card border border-border rounded-card p-5 hover:shadow-card transition-smooth hover:translate-y-[-4px]">
  Contenido de card
</div>
```

### Input

```tsx
<input
  type="text"
  className="w-full bg-bg-subtle border border-border text-text-primary placeholder:text-text-muted rounded-input px-3 py-2 focus:border-tierra focus:ring-2 focus:ring-tierra-pale transition-smooth"
  placeholder="Ingresa texto..."
/>
```

---

## 🌙 Dark Mode

### Uso en componentes

```tsx
import { useTheme } from '@/hooks/useTheme'

export function MyComponent() {
  const { theme, toggle } = useTheme()

  return (
    <div className="bg-bg text-text-primary transition-smooth">
      <button onClick={toggle}>
        {theme === 'light' ? '🌙 Oscuro' : '☀️ Claro'}
      </button>
    </div>
  )
}
```

### Store de tema

```tsx
import { useThemeStore } from '@/store/themeStore'

export function ThemeToggle() {
  const { theme, toggle } = useThemeStore()

  return (
    <button onClick={toggle} aria-label="Cambiar tema">
      {theme === 'light' ? '🌙' : '☀️'}
    </button>
  )
}
```

La preferencia se guarda automáticamente en `localStorage` con clave `nc-theme-store`.

---

## 📦 Constantes y Tokens

Todos los tokens están centralizados en:
```typescript
import { DESIGN_TOKENS, COMPONENT_VARIANTS } from '@/constants/designTokens'

console.log(DESIGN_TOKENS.colors.light.tierra)      // #8B4513
console.log(DESIGN_TOKENS.typography.sizes.h1)      // clamp(26px, 5vw, 42px)
console.log(COMPONENT_VARIANTS.button.primary)      // { bg, color, hover }
```

---

## ✅ Checklist de Implementación

- [x] Variables CSS en `index.css` (luz + oscuro)
- [x] Tailwind config extendido en `tailwind.config.ts`
- [x] Google Fonts importadas
- [x] Hook `useTheme` para toggle dark mode
- [x] Store `useThemeStore` para estado global
- [x] Clases de tipografía (`.text-h1`, `.text-body`, etc.)
- [x] Constantes de tokens en `designTokens.ts`
- [x] Estilos base y animaciones en `index.css`
- [ ] Componentes UI (Button.tsx, Badge.tsx, etc.) — Paso 2
- [ ] Navbar con toggle dark mode — Paso 3
- [ ] Página perfil artista — Paso 4

---

## 🎯 Reglas de Implementación

1. **NUNCA hardcodear colores hex.** Usar siempre variables CSS.
2. **Todos los componentes aceptan `className` prop** para extensión.
3. **Tipografía:** Font-display solo en títulos; font-body en resto; font-accent solo en taglines.
4. **Border-radius:** Cards 12-14px, botones 7px, tags 99px, inputs 8px, avatar 50%.
5. **Sombras:** Cards en hover usan `shadow-card`.
6. **Focus visible:** Outline 2px `--tierra`, offset 2px (WCAG AA).
7. **Responsive:** sm:640px, md:768px, lg:1024px, xl:1280px.
8. **Contraste mínimo:** 4.5:1 texto sobre fondo en ambos modos.

---

## 🚀 Próximos Pasos

- **Paso 2:** Crear componentes UI (Button.tsx, Badge.tsx, Alert.tsx, Card.tsx, Input.tsx)
- **Paso 3:** Navbar.tsx y Footer.tsx
- **Paso 4:** ArtistProfilePage.tsx con mockup completo

