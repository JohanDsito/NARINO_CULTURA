import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'

import App from '@/App'

// El enrutador real tiene su propia prueba (router/router.test.tsx): aquí solo se comprueba que App lo monta.
vi.mock('@/router', async () => {
  const { createMemoryRouter } = await import('react-router-dom')
  const { createElement } = await import('react')
  return { router: createMemoryRouter([{ path: '/', element: createElement('p', null, 'inicio-de-prueba') }]) }
})

describe('App', () => {
  it('monta el enrutador de la aplicación', async () => {
    render(<App />)
    expect(await screen.findByText('inicio-de-prueba')).toBeInTheDocument()
  })
})
