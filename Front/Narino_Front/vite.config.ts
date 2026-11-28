import { configDefaults, defineConfig } from 'vitest/config'
import type { Plugin } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

/**
 * Abre la conexión con la API (DNS + TLS) mientras se descarga el JavaScript, en vez de esperar a la primera
 * petición. Usa el mismo origen que `src/config/env.ts` (VITE_API_BASE_URL o la API de producción).
 */
function preconnectApi(): Plugin {
  let apiBaseUrl = ''
  return {
    name: 'preconnect-api',
    // config.env ya trae VITE_* del entorno del proceso y de los .env del modo en curso (--mode, envDir)
    configResolved(config) {
      apiBaseUrl = String(config.env.VITE_API_BASE_URL ?? '')
    },
    transformIndexHtml(html) {
      const raw = apiBaseUrl || 'https://narinocultura-production.up.railway.app'
      try {
        const origin = new URL(raw).origin
        return html.replace('</title>', `</title>
    <link rel="preconnect" href="${origin}" crossorigin />`)
      } catch {
        return html
      }
    },
  }
}

export default defineConfig({
  plugins: [react(), preconnectApi()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          // Solo el núcleo de React va al chunk de arranque. Un includes('node_modules/react') también
          // capturaba react-hook-form, react-icons, react-day-picker…, y los metía en la carga inicial.
          if (/node_modules\/(react|react-dom|scheduler|react-router|react-router-dom)\//.test(id)) {
            return 'vendor'
          }
          if (id.includes('node_modules/@tanstack/react-query')) {
            return 'query'
          }
          // recharts y sus dependencias (d3-*, victory-vendor…) quedan al ser importados solo por la
          // analítica del artista (lazy); sin chunk manual para que no se arrastren al inicio.
        },
      },
    },
  },

  test: {
    globals: true,
    // e2e/ son pruebas de Playwright: las corre `npm run e2e`, no Vitest
    exclude: [...configDefaults.exclude, 'e2e/**'],
    environment: 'jsdom',
    env: {
      VITE_API_BASE_URL: 'https://narinocultura-production.up.railway.app/api/v1',
    },

    setupFiles: './src/test/setup.ts',
    // userEvent escribe carácter por carácter; en máquinas lentas 5 s no alcanza
    testTimeout: 20_000,

    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
    },
  },
})







