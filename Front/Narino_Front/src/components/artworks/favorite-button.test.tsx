import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import { toast } from 'sonner'

import { addFavorite, getFavorites, removeFavorite } from '@/api/marketplace.api'
import { FavoriteButton } from '@/components/artworks/favorite-button'
import { useAuthStore } from '@/store/authStore'

vi.mock('@/api/marketplace.api', () => ({
  getFavorites: vi.fn(),
  addFavorite: vi.fn(),
  removeFavorite: vi.fn(),
}))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedGet = vi.mocked(getFavorites)
const mockedAdd = vi.mocked(addFavorite)
const mockedRemove = vi.mocked(removeFavorite)

function LoginProbe() {
  const location = useLocation()
  return <p>Login (volver a {(location.state as { from?: string } | null)?.from})</p>
}

function renderButton() {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={['/artworks/a1']}>
        <Routes>
          <Route path="/artworks/:id" element={<FavoriteButton artworkId="a1" />} />
          <Route path="/login" element={<LoginProbe />} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('FavoriteButton', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ isAuthenticated: true, accessToken: 't', refreshToken: 'r' })
    mockedGet.mockResolvedValue([])
    mockedAdd.mockResolvedValue({ detail: 'ok' })
    mockedRemove.mockResolvedValue({ detail: 'ok' })
  })

  it('sin sesión lleva al login y recuerda la obra para volver', async () => {
    useAuthStore.setState({ isAuthenticated: false, accessToken: null, refreshToken: null })
    renderButton()
    fireEvent.click(screen.getByRole('button', { name: /guardar en favoritos/i }))
    expect(await screen.findByText('Login (volver a /artworks/a1)')).toBeInTheDocument()
    expect(mockedGet).not.toHaveBeenCalled()
  })

  it('agrega a favoritos y el corazón cambia al instante', async () => {
    renderButton()
    const boton = await screen.findByRole('button', { name: /guardar en favoritos/i })
    await waitFor(() => expect(mockedGet).toHaveBeenCalled())
    mockedGet.mockResolvedValue([
      { id: 'f1', artwork_id: 'a1', title: 'Obra', artwork_price: '1', artwork_image_url: '' },
    ])
    fireEvent.click(boton)
    expect(await screen.findByRole('button', { name: /en tus favoritos/i })).toHaveAttribute(
      'aria-pressed',
      'true',
    )
    expect(mockedAdd).toHaveBeenCalledWith('a1')
  })

  it('quita de favoritos si ya estaba guardada', async () => {
    mockedGet.mockResolvedValue([
      { id: 'f1', artwork_id: 'a1', title: 'Obra', artwork_price: '1', artwork_image_url: '' },
    ])
    renderButton()
    fireEvent.click(await screen.findByRole('button', { name: /en tus favoritos/i }))
    await waitFor(() => expect(mockedRemove).toHaveBeenCalledWith('a1'))
  })

  it('si el servidor falla vuelve al estado anterior y avisa', async () => {
    mockedAdd.mockRejectedValue(new Error('sin red'))
    renderButton()
    const boton = await screen.findByRole('button', { name: /guardar en favoritos/i })
    await waitFor(() => expect(mockedGet).toHaveBeenCalled())
    fireEvent.click(boton)
    await waitFor(() => expect(toast.error).toHaveBeenCalled())
    expect(await screen.findByRole('button', { name: /guardar en favoritos/i })).toHaveAttribute(
      'aria-pressed',
      'false',
    )
  })
})
