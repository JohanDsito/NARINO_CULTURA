import type { Config } from 'tailwindcss'

/**
 * Design system "Carnaval": los colores viven como variables CSS en `src/index.css` (modo claro y `.dark`).
 * Se envuelven en `color-mix` para que Tailwind pueda aplicar opacidad (`bg-azul/10`, `border-error/30`, ...).
 */
const token = (name: string) =>
  `color-mix(in srgb, var(--${name}) calc(<alpha-value> * 100%), transparent)`

/** Cada acento: tinta (texto), relleno, texto encima del relleno y tinte. */
const accent = (name: string) => ({
  [name]: token(name),
  [`${name}-fill`]: token(`${name}-fill`),
  [`on-${name}`]: token(`on-${name}`),
  [`${name}-tint`]: token(`${name}-tint`),
})

export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        display: ['Inter Variable', 'Inter Fallback', 'system-ui', 'sans-serif'],
        body: ['Inter Variable', 'Inter Fallback', 'system-ui', 'sans-serif'],
        accent: ['Inter Variable', 'Inter Fallback', 'system-ui', 'sans-serif'],
      },
      colors: {
        bg: token('bg'),
        'bg-card': token('bg-card'),
        'bg-subtle': token('bg-subtle'),
        border: token('border'),
        'border-strong': token('border-strong'),

        ...accent('azul'),
        ...accent('tomate'),
        ...accent('naranja'),
        ...accent('oro'),
        ...accent('magenta'),
        ...accent('verde'),

        // Alias de los tokens anteriores (ver index.css)
        tierra: token('tierra'),
        'tierra-light': token('tierra-light'),
        'tierra-pale': token('tierra-pale'),
        'on-tierra': token('on-tierra'),

        volcan: token('volcan'),
        'volcan-mid': token('volcan-mid'),

        'oro-light': token('oro-light'),
        'oro-pale': token('oro-pale'),

        selva: token('selva'),
        'selva-light': token('selva-light'),
        'selva-pale': token('selva-pale'),

        indigo: token('indigo'),
        'indigo-light': token('indigo-light'),
        'indigo-pale': token('indigo-pale'),

        error: token('error'),
        success: token('success'),

        text: {
          primary: token('text-primary'),
          secondary: token('text-secondary'),
          muted: token('text-muted'),
        },
      },
      // `border` sin color usa el borde del tema (antes caía en el gris de Tailwind, muy claro en oscuro)
      borderColor: {
        DEFAULT: token('border'),
      },
      borderRadius: {
        card: '22px',
        'card-lg': '22px',
        btn: '9999px',
        tag: '9999px',
        input: '14px',
      },
      boxShadow: {
        card: 'var(--shadow-card)',
      },
      transitionTimingFunction: {
        smooth: 'cubic-bezier(0.4, 0, 0.2, 1)',
        spring: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
      },
    },
  },
  plugins: [],
} satisfies Config
