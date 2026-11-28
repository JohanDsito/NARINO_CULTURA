import { configDefaults, defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (
            id.includes('node_modules/react') ||
            id.includes('node_modules/react-dom') ||
            id.includes('node_modules/react-router-dom')
          ) {
            return 'vendor'
          }
          if (id.includes('node_modules/@tanstack/react-query')) {
            return 'query'
          }
          if (id.includes('node_modules/recharts')) {
            return 'charts'
          }
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
      // Sin `include`, v8 solo mide los archivos que alguna prueba importa y las páginas sin
      // pruebas quedarían fuera del porcentaje: se mide todo el código de la app.
      include: ['src/**/*.{ts,tsx}'],
      // El reporte también se genera si alguna prueba falla: así se ve qué falta aunque la corrida no pase
      reportOnFailure: true,
      exclude: [
        // Arranque de la app (createRoot sobre #root): no hay lógica que probar, lo cubren las pruebas e2e
        'src/main.tsx',
        // Declaraciones de tipos: no generan código ejecutable
        'src/**/*.d.ts',
        // Infraestructura de pruebas, no código de la app
        'src/test/**',
        'src/**/*.test.{ts,tsx}',
      ],
    },
  },
})







