import type { ReactElement } from 'react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

import { LocationProbe } from './location-probe'

interface Options {
  /** Ruta inicial (con query string si hace falta). */
  route?: string
  /** Patrón de ruta donde se monta la página (para useParams). */
  path?: string
  /** Estado de navegación inicial. */
  state?: unknown
}

/**
 * Renderiza con React Query (sin reintentos), router en memoria y una sonda
 * (data-testid="location") que muestra la ruta actual para verificar navegación.
 */
export function renderWithProviders(ui: ReactElement, { route = '/', path = '*', state }: Options = {}) {
  const [pathname, query] = route.split('?')
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  })
  return {
    queryClient,
    ...render(
      <QueryClientProvider client={queryClient}>
        <MemoryRouter initialEntries={[{ pathname, search: query ? `?${query}` : '', state }]}>
          <LocationProbe />
          <Routes>
            <Route path={path} element={ui} />
            <Route path="*" element={<div>otra-ruta</div>} />
          </Routes>
        </MemoryRouter>
      </QueryClientProvider>,
    ),
  }
}
