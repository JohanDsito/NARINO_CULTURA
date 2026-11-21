import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

import { getFavorites, removeFavorite, type FavoriteItem } from '@/api/marketplace.api'
import FavoritesPage from '@/pages/user/FavoritesPage'
import { useAuthStore } from '@/store/authStore'

vi.mock('@/api/marketplace.api', () => ({
  getFavorites: vi.fn(),
  addFavorite: vi.fn(),
  removeFavorite: vi.fn(),
}))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedGet = vi.mocked(getFavorites)
const mockedRemove = vi.mocked(removeFavorite)

const VOLCAN: FavoriteItem = {
  id: 'f1',
  artwork_id: 'a1',
  title: 'Volcán Galeras',
  artwork_price: '350000.00',
  artwork_status: 'DISPONIBLE',
  artwork_image_url: 'https://img.test/volcan.jpg',
  artist_name: 'Ana Barniz',
}
const VENDIDA: FavoriteItem = {
  id: 'f2',
  artwork_id: 'a2',
  title: 'Carnaval',
  artwork_price: '120000.00',
  artwork_status: 'VENDIDA',
  artwork_image_url: '',
}

function renderPage() {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <FavoritesPage />
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('FavoritesPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ isAuthenticated: true, accessToken: 't', refreshToken: 'r' })
    mockedGet.mockResolvedValue([VOLCAN, VENDIDA])
    mockedRemove.mockResolvedValue({ detail: 'ok' })
  })

  it('lista las obras guardadas con su precio, artista, estado y enlace', async () => {
    renderPage()
    expect(await screen.findByRole('link', { name: 'Volcán Galeras' })).toHaveAttribute('href', '/artworks/a1')
    expect(screen.getByText('Ana Barniz')).toBeInTheDocument()
    expect(screen.getByText(/350\.000/)).toBeInTheDocument()
    expect(screen.getByText('Vendida')).toBeInTheDocument()
  })

  it('quita una obra de la lista al instante', async () => {
    renderPage()
    mockedGet.mockResolvedValue([VENDIDA])
    fireEvent.click(await screen.findByRole('button', { name: 'Quitar «Volcán Galeras» de favoritos' }))
    await waitFor(() => expect(screen.queryByText('Volcán Galeras')).not.toBeInTheDocument())
    expect(mockedRemove).toHaveBeenCalledWith('a1')
  })

  it('sin favoritos invita a explorar el catálogo', async () => {
    mockedGet.mockResolvedValue([])
    renderPage()
    expect(await screen.findByRole('link', { name: 'Explorar el catálogo' })).toHaveAttribute('href', '/artworks')
  })

  it('permite reintentar si falla la carga', async () => {
    mockedGet.mockRejectedValueOnce(new Error('sin red'))
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: 'Reintentar' }))
    expect(await screen.findByText('Volcán Galeras')).toBeInTheDocument()
  })
})
