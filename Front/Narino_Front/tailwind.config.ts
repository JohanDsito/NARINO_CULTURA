import type { Config } from 'tailwindcss'

/**
 * Los colores del design system viven como variables CSS en `src/index.css`
 * (modo claro y `.dark`). Se envuelven en `color-mix` para que Tailwind pueda
 * aplicar modificadores de opacidad (`bg-tierra/10`, `border-error/30`, ...).
 */
const token = (name: string) =>
  `color-mix(in srgb, var(--${name}) calc(<alpha-value> * 100%), transparent)`

export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        display: ['"Playfair Display"', 'serif'],
        body: ['"DM Sans"', 'sans-serif'],
        accent: ['"Cormorant Garamond"', 'serif'],
      },
      colors: {
        bg: token('bg'),
        'bg-card': token('bg-card'),
        'bg-subtle': token('bg-subtle'),
        border: token('border'),

        tierra: token('tierra'),
        'tierra-light': token('tierra-light'),
        'tierra-pale': token('tierra-pale'),

        volcan: token('volcan'),
        'volcan-mid': token('volcan-mid'),

        oro: token('oro'),
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
      borderRadius: {
        card: '12px',
        'card-lg': '14px',
        btn: '7px',
        tag: '99px',
        input: '8px',
      },
      boxShadow: {
        card: '0 12px 28px rgba(0,0,0,0.18)',
      },
      transitionTimingFunction: {
        smooth: 'cubic-bezier(0.4, 0, 0.2, 1)',
      },
    },
  },
  plugins: [],
} satisfies Config
