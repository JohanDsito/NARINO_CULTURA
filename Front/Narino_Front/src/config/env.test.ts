import { describe, it, expect, vi, afterEach } from 'vitest'

describe('API_BASE_URL', () => {
  afterEach(() => {
    vi.unstubAllEnvs()
    vi.resetModules()
  })

  it('quita barras finales y el sufijo /api/v1', async () => {
    vi.stubEnv('VITE_API_BASE_URL', 'https://api.test/api/v1/')
    vi.resetModules()
    const { API_BASE_URL } = await import('@/config/env')
    expect(API_BASE_URL).toBe('https://api.test')
  })

  it('usa el backend de producción si la variable está vacía', async () => {
    vi.stubEnv('VITE_API_BASE_URL', '')
    vi.resetModules()
    const { API_BASE_URL } = await import('@/config/env')
    expect(API_BASE_URL).toBe('https://narinocultura-production.up.railway.app')
  })
})
