import type { Config } from 'tailwindcss'

export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        display: ['"Playfair Display"', 'serif'],
        body:    ['"DM Sans"', 'sans-serif'],
        accent:  ['"Cormorant Garamond"', 'serif'],
      },
      colors: {
        bg:           'var(--bg)',
        'bg-card':    'var(--bg-card)',
        'bg-subtle':  'var(--bg-subtle)',
        border:       'var(--border)',

        tierra:       'var(--tierra)',
        'tierra-light': 'var(--tierra-light)',
        'tierra-pale':  'var(--tierra-pale)',

        volcan:       'var(--volcan)',
        'volcan-mid': 'var(--volcan-mid)',

        oro:          'var(--oro)',
        'oro-light':  'var(--oro-light)',
        'oro-pale':   'var(--oro-pale)',

        selva:        'var(--selva)',
        'selva-light':'var(--selva-light)',
        'selva-pale': 'var(--selva-pale)',

        indigo:       'var(--indigo)',
        'indigo-light':'var(--indigo-light)',
        'indigo-pale': 'var(--indigo-pale)',

        error:        'var(--error)',
        success:      'var(--success)',

        text: {
          primary:   'var(--text-primary)',
          secondary: 'var(--text-secondary)',
          muted:     'var(--text-muted)',
        },
      },
      borderRadius: {
        card:   '12px',
        'card-lg': '14px',
        btn:    '7px',
        tag:    '99px',
        input:  '8px',
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