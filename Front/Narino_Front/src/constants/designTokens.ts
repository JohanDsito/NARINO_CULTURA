/**
 * Design System Tokens para Nariño Cultura
 * Fuente única de verdad para colores, tipografía y espaciado
 * Estos valores están sincronizados con index.css y tailwind.config.ts
 */

export const DESIGN_TOKENS = {
  colors: {
    light: {
      bg: '#F7F3EE',
      'bg-card': '#FFFFFF',
      'bg-subtle': '#EDE8E1',
      'text-primary': '#1A1208',
      'text-secondary': '#5C4F3A',
      'text-muted': '#9C8E78',
      border: '#DDD6CA',

      tierra: '#8B4513',
      'tierra-light': '#C1763A',
      'tierra-pale': '#F0DCC8',

      volcan: '#2D1B00',
      'volcan-mid': '#4A3320',

      oro: '#C9921A',
      'oro-light': '#F0C060',
      'oro-pale': '#FBF0D5',

      selva: '#2E5E30',
      'selva-light': '#5A9B5C',
      'selva-pale': '#D4EBD5',

      indigo: '#3B3580',
      'indigo-light': '#6B65C0',
      'indigo-pale': '#E1E0F5',

      error: '#C0392B',
      success: '#27AE60',
    },

    dark: {
      bg: '#141008',
      'bg-card': '#1E1710',
      'bg-subtle': '#2A2016',
      'text-primary': '#F5EFE5',
      'text-secondary': '#C4B89E',
      'text-muted': '#7A6E5E',
      border: '#352A1E',

      tierra: '#D4763E',
      'tierra-light': '#E8A06A',
      'tierra-pale': '#3A2010',

      volcan: '#F0E8D8',
      'volcan-mid': '#C4B89E',

      oro: '#E8B030',
      'oro-light': '#F5CC6A',
      'oro-pale': '#2E2000',

      selva: '#4A9E4C',
      'selva-light': '#7EC880',
      'selva-pale': '#0E2010',

      indigo: '#7B75D8',
      'indigo-light': '#A8A4E8',
      'indigo-pale': '#181630',

      error: '#E55A4A',
      success: '#4CC870',
    },
  },

  typography: {
    fontFamily: {
      display: '"Playfair Display", serif',
      body: '"DM Sans", sans-serif',
      accent: '"Cormorant Garamond", serif',
      mono: '"DM Sans", monospace',
    },

    sizes: {
      hero: 'clamp(30px, 6vw, 50px)',
      h1: 'clamp(26px, 5vw, 42px)',
      h2: '28px',
      h3: '21px',
      body: '15px',
      small: '13px',
      label: '11px',
      micro: '10px',
    },

    weights: {
      thin: 300,
      normal: 400,
      medium: 500,
      semibold: 600,
      bold: 700,
      black: 900,
    },

    lineHeight: {
      tight: 1.1,
      snug: 1.2,
      normal: 1.5,
      relaxed: 1.6,
      loose: 1.8,
    },
  },

  spacing: {
    xs: '4px',
    sm: '8px',
    md: '12px',
    lg: '16px',
    xl: '24px',
    '2xl': '32px',
    '3xl': '48px',
    '4xl': '64px',
  },

  borderRadius: {
    none: '0',
    sm: '4px',
    btn: '7px',
    input: '8px',
    card: '12px',
    'card-lg': '14px',
    tag: '99px',
    avatar: '50%',
  },

  shadows: {
    none: 'none',
    sm: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
    base: '0 4px 12px rgba(0, 0, 0, 0.08)',
    card: '0 12px 28px rgba(0, 0, 0, 0.18)',
    toast: '0 4px 16px rgba(0, 0, 0, 0.3)',
    lg: '0 20px 40px rgba(0, 0, 0, 0.2)',
  },

  transitions: {
    fast: '0.15s cubic-bezier(0.4, 0, 0.2, 1)',
    base: '0.35s cubic-bezier(0.4, 0, 0.2, 1)',
    slow: '0.5s cubic-bezier(0.4, 0, 0.2, 1)',
  },

  zIndex: {
    hide: '-1',
    auto: 'auto',
    base: '0',
    dropdown: '1000',
    sticky: '1020',
    fixed: '1030',
    modal: '1040',
    popover: '1050',
    tooltip: '1060',
  },
} as const

/**
 * Variantes de componentes predefinidas
 */
export const COMPONENT_VARIANTS = {
  button: {
    primary: {
      bg: 'var(--tierra)',
      color: '#fff',
      hover: 'var(--tierra-light)',
    },
    secondary: {
      bg: 'transparent',
      border: 'var(--tierra)',
      color: 'var(--tierra)',
      hover: 'var(--tierra-pale)',
    },
    gold: {
      bg: 'var(--oro)',
      color: '#2D1B00',
      hover: 'var(--oro-light)',
    },
    ghost: {
      bg: 'transparent',
      color: 'var(--text-primary)',
      hover: 'var(--bg-subtle)',
    },
  },

  badge: {
    tierra: {
      bg: 'var(--tierra-pale)',
      color: 'var(--tierra)',
    },
    oro: {
      bg: 'var(--oro-pale)',
      color: 'var(--oro)',
    },
    selva: {
      bg: 'var(--selva-pale)',
      color: 'var(--selva)',
    },
    indigo: {
      bg: 'var(--indigo-pale)',
      color: 'var(--indigo)',
    },
  },

  alert: {
    success: {
      bg: 'var(--selva-pale)',
      color: 'var(--selva)',
      borderLeft: '3px solid var(--selva)',
    },
    warning: {
      bg: 'var(--oro-pale)',
      color: 'var(--oro)',
      borderLeft: '3px solid var(--oro)',
    },
    error: {
      bg: '#FFE8E6',
      color: 'var(--error)',
      borderLeft: '3px solid var(--error)',
    },
    info: {
      bg: 'var(--indigo-pale)',
      color: 'var(--indigo)',
      borderLeft: '3px solid var(--indigo)',
    },
  },
} as const

export type ButtonVariant = keyof typeof COMPONENT_VARIANTS.button
export type BadgeVariant = keyof typeof COMPONENT_VARIANTS.badge
export type AlertVariant = keyof typeof COMPONENT_VARIANTS.alert
