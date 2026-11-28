import { describe, it, expect, vi, afterEach } from 'vitest'

import { redirectToLogin } from '@/utils/navigation'

describe('redirectToLogin', () => {
  afterEach(() => vi.unstubAllGlobals())

  it('asigna /login a la dirección de la página', () => {
    const location = { href: '/artworks' }
    vi.stubGlobal('location', location)
    redirectToLogin()
    expect(location.href).toBe('/login')
  })
})