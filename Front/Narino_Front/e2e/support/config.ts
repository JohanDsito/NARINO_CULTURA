// Direcciones y secretos FALSOS de las pruebas e2e (coinciden con config/settings/e2e.py del backend).
export const API_URL = (process.env.E2E_API_URL ?? 'http://127.0.0.1:8000').replace(/\/+$/, '')
export const WEB_URL = (process.env.E2E_BASE_URL ?? 'http://127.0.0.1:4173').replace(/\/+$/, '')

export const WOMPI_EVENTS_SECRET = process.env.E2E_WOMPI_EVENTS_SECRET ?? 'e2e_events_secret'

// Usuarios que siembra `manage.py seed_demo`
export const DEMO_PASSWORD = 'Demo1234!'
export const ADMIN = { email: 'admin@demo.test', password: DEMO_PASSWORD }
export const ARTIST = { email: 'artista@demo.test', password: DEMO_PASSWORD }
export const BUYER = { email: 'comprador@demo.test', password: DEMO_PASSWORD }

/** Texto único por ejecución: evita choques entre pruebas y entre corridas sobre la misma base. */
export function unico(prefijo: string): string {
  return `${prefijo} ${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`
}
