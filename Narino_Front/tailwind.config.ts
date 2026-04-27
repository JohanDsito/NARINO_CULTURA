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
        mono:    ['"DM Sans"', 'monospace'],
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
        card:     '12px',
        'card-lg': '14px',
        btn:      '7px',
        tag:      '99px',
        input:    '8px',
        avatar:   '50%',
      },
      boxShadow: {
        card:  '0 12px 28px rgba(0,0,0,0.18)',
        'card-sm': '0 4px 12px rgba(0,0,0,0.08)',
        toast: '0 4px 16px rgba(0,0,0,0.3)',
      },
      transitionTimingFunction: {
        smooth: 'cubic-bezier(0.4, 0, 0.2, 1)',
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-out',
        'slide-up': 'slideUp 0.35s cubic-bezier(0.4, 0, 0.2, 1)',
        'scale-in': 'scaleIn 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(20px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        scaleIn: {
          '0%': { transform: 'scale(0.95)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
      },
      spacing: {
        '18': '4.5rem',
        '22': '5.5rem',
        '26': '6.5rem',
        '30': '7.5rem',
      },
      fontSize: {
        'micro': '10px',
        'xs': '11px',
      },
    },
  },
  plugins: [],
} satisfies Config