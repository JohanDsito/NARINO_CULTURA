import { defineConfig, devices } from '@playwright/test'

// Pruebas end-to-end: front real (build + vite preview) contra el back real con config.settings.e2e.
// Solo Chromium. Nunca contra producción: global-setup.ts se detiene si alguna URL menciona railway.
const baseURL = process.env.E2E_BASE_URL ?? 'http://127.0.0.1:4173'
const enCI = Boolean(process.env.CI)

export default defineConfig({
  testDir: './e2e',
  testMatch: '**/*.spec.ts',
  globalSetup: './e2e/global-setup.ts',
  // Los tests comparten la misma base: se corren de uno en uno para que sean deterministas
  workers: 1,
  fullyParallel: false,
  forbidOnly: enCI,
  retries: enCI ? 2 : 0,
  timeout: 60_000,
  expect: { timeout: 10_000 },
  reporter: [['list'], ['html', { open: 'never', outputFolder: 'playwright-report' }]],
  outputDir: 'test-results',
  use: {
    baseURL,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    locale: 'es-CO',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
})
