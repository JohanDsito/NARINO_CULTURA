import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { getAdminMetrics, getAdminTransactions, getPendingArtworks, getPendingEvents } from '@/api/admin.api'
import { getArtistBySlug, listArtistProfiles } from '@/api/artists.api'
import { aiEnhanceArtwork, getArtworkById, getArtworks } from '@/api/artworks.api'
import { verifyEmail } from '@/api/auth.api'
import { getServerCart, removeCartItem } from '@/api/marketplace.api'
import { listMusicians } from '@/api/musicians.api'
import { eventsApi } from '@/api/events.api'
import AdminDashboardPage from '@/pages/admin/AdminDashboardPage'
import ArtistProfilePage from '@/pages/artist/ArtistProfilePage'
import ArtistsPage from '@/pages/artists/ArtistsPage'
import ArtworkDetailPage from '@/pages/artworks/ArtworkDetailPage'
import VerifyEmailPage from '@/pages/auth/VerifyEmailPage'
import CheckoutPage from '@/pages/checkout/CheckoutPage'
import ArtistEventCreatePage from '@/pages/events/ArtistEventCreatePage'
import { useAuthStore } from '@/store/authStore'
import { makeArtwork } from '@/test/fixtures'
import { renderWithProviders } from '@/test/render'
import type { ArtistProfile, User } from '@/types'

vi.mock('@/api/admin.api', () => ({
  getAdminMetrics: vi.fn(),
  getAdminTransactions: vi.fn(),
  getPendingArtworks: vi.fn(),
  getPendingEvents: vi.fn(),
}))
vi.mock('@/api/artists.api', () => ({ getArtistBySlug: vi.fn(), listArtistProfiles: vi.fn(), followArtist: vi.fn() }))
vi.mock('@/api/artworks.api', () => ({ getArtworks: vi.fn(), getArtworkById: vi.fn(), aiEnhanceArtwork: vi.fn() }))
vi.mock('@/api/auth.api', () => ({ verifyEmail: vi.fn() }))
vi.mock('@/api/marketplace.api', () => ({ getServerCart: vi.fn(), removeCartItem: vi.fn(), checkout: vi.fn(), addCartItem: vi.fn() }))
vi.mock('@/api/musicians.api', () => ({ listMusicians: vi.fn() }))
vi.mock('@/api/events.api', () => ({ eventsApi: { createArtistEvent: vi.fn() } }))
vi.mock('@/hooks/useStartPayment', () => ({ useStartPayment: () => ({ mutate: vi.fn(), isPending: false }) }))
vi.mock('@/components/artworks/favorite-button', () => ({ FavoriteButton: () => null }))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

beforeEach(() => {
  vi.clearAllMocks()
  useAuthStore.setState({ isAuthenticated: false, user: null })
})

describe('AdminDashboardPage: estado de transacción desconocido', () => {
  it('si el servidor manda un estado nuevo muestra el texto tal cual', async () => {
    vi.mocked(getAdminMetrics).mockResolvedValue({} as never)
    vi.mocked(getPendingArtworks).mockResolvedValue([])
    vi.mocked(getPendingEvents).mockResolvedValue([])
    vi.mocked(getAdminTransactions).mockResolvedValue([
      { id: 'tx000000', order_id: 'abc12345', order_type: 'COMPRA_DIRECTA', status: 'EN_REVISION', total_amount: '1000', created_at: '2026-01-01T00:00:00Z' },
    ] as never)
    renderWithProviders(<AdminDashboardPage />)
    expect(await screen.findByText('EN_REVISION')).toBeInTheDocument()
    expect(screen.getByText('#ABC12345')).toBeInTheDocument()
  })
})

describe('ArtistsPage', () => {
  const artist = (over: Partial<ArtistProfile>) =>
    ({ id: 'a', user_id: 'u', slug: 'a', artistic_name: 'Ana', discipline: 'Pintura', city: '', followers_count: 1, is_public: false, ...over }) as ArtistProfile

  it('sin ciudad deja la línea vacía, usa singular de seguidor y oculta "Público"', async () => {
    vi.mocked(listMusicians).mockResolvedValue({ results: [] } as never)
    vi.mocked(listArtistProfiles).mockResolvedValue([artist({})])
    renderWithProviders(<ArtistsPage />)
    expect(await screen.findByText('1 seguidor')).toBeInTheDocument()
    expect(screen.queryByText(/📍/)).not.toBeInTheDocument()
    expect(screen.queryByText('Público')).not.toBeInTheDocument()
  })

  it('una búsqueda sin coincidencias dice "Sin resultados para tu búsqueda."', async () => {
    vi.mocked(listMusicians).mockResolvedValue({ results: [] } as never)
    vi.mocked(listArtistProfiles).mockResolvedValue([])
    renderWithProviders(<ArtistsPage />)
    fireEvent.change(screen.getByLabelText('Buscar artistas'), { target: { value: 'zzz' } })
    expect(await screen.findByText('Sin resultados para tu búsqueda.')).toBeInTheDocument()
  })
})

describe('ArtistProfilePage: portafolio aún sin cargar', () => {
  it('muestra el perfil y el vacío mientras las obras no llegan', async () => {
    vi.mocked(getArtistBySlug).mockResolvedValue({ slug: 'ana', artistic_name: 'Ana', followers_count: 0, is_public: true } as ArtistProfile)
    vi.mocked(getArtworks).mockReturnValue(new Promise(() => {}))
    renderWithProviders(<ArtistProfilePage />, { route: '/artists/ana', path: '/artists/:slug' })
    expect(await screen.findByText('Aún no hay obras publicadas')).toBeInTheDocument()
  })
})

describe('ArtworkDetailPage: IA en curso y galería sin lista', () => {
  it('mientras mejora la descripción lo indica; una obra sin lista de imágenes igual se muestra', async () => {
    useAuthStore.setState({ isAuthenticated: true })
    vi.mocked(getArtworkById).mockResolvedValue(makeArtwork({ images: undefined as never }))
    vi.mocked(aiEnhanceArtwork).mockReturnValue(new Promise(() => {}))
    renderWithProviders(<ArtworkDetailPage />, { route: '/artworks/art-1', path: '/artworks/:id' })
    fireEvent.click(await screen.findByRole('button', { name: /Mejorar descripción con IA/ }))
    expect(await screen.findByRole('button', { name: /Mejorando con IA…/ })).toBeDisabled()
  })
})

describe('VerifyEmailPage: desmontar antes de la respuesta', () => {
  it('no actualiza el estado si la página ya se cerró (éxito y error)', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => {})
    try {
      let resolveOk!: (v: { message: string }) => void
      vi.mocked(verifyEmail).mockReturnValueOnce(new Promise((r) => { resolveOk = r }))
      const first = renderWithProviders(<VerifyEmailPage />, { route: '/verify-email?token=abc', path: '/verify-email' })
      first.unmount()
      resolveOk({ message: 'ok' })

      let rejectErr!: (e: Error) => void
      vi.mocked(verifyEmail).mockReturnValueOnce(new Promise((_, r) => { rejectErr = r }))
      const second = renderWithProviders(<VerifyEmailPage />, { route: '/verify-email?token=abc', path: '/verify-email' })
      second.unmount()
      rejectErr(new Error('x'))
      await new Promise((r) => setTimeout(r, 20))
      expect(verifyEmail).toHaveBeenCalledTimes(2)
      expect(consoleError).not.toHaveBeenCalled()
    } finally {
      consoleError.mockRestore()
    }
  })
})

describe('CheckoutPage: quitar obra en curso', () => {
  it('bloquea solo el botón de la obra que se está quitando', async () => {
    vi.mocked(getServerCart).mockResolvedValue({
      id: 'c', user: 'u', created_at: '', updated_at: '',
      items: [
        { id: 'c1', artwork: 'w1', artwork_title: 'Volcán', artwork_price: '1', created_at: '' },
        { id: 'c2', artwork: 'w2', artwork_title: 'Carnaval', artwork_price: '1', created_at: '' },
      ],
    } as never)
    vi.mocked(removeCartItem).mockReturnValue(new Promise(() => {}))
    renderWithProviders(<CheckoutPage />)
    fireEvent.click(await screen.findByRole('button', { name: 'Quitar «Volcán» del carrito' }))
    await waitFor(() => expect(removeCartItem).toHaveBeenCalledWith('w1'))
    expect(screen.getByRole('button', { name: 'Quitar «Volcán» del carrito' })).toBeDisabled()
    expect(screen.getByRole('button', { name: 'Quitar «Carnaval» del carrito' })).toBeEnabled()
  })
})

describe('ArtistEventCreatePage: flyer por archivo sin elegir y envío en curso', () => {
  it('pestaña de archivo sin archivo envía sin flyer; mientras envía dice "Enviando..."', async () => {
    useAuthStore.setState({ user: { id: 'u1' } as User })
    vi.mocked(eventsApi.createArtistEvent).mockReturnValue(new Promise(() => {}) as never)
    renderWithProviders(<ArtistEventCreatePage />, { route: '/dashboard/events/new', path: '/dashboard/events/new' })
    fireEvent.change(screen.getByLabelText('Nombre del evento *'), { target: { value: 'Evento' } })
    fireEvent.change(screen.getByLabelText('Tipo de evento *'), { target: { value: 'OTRO' } })
    fireEvent.change(screen.getByLabelText('Lugar *'), { target: { value: 'Pasto' } })
    fireEvent.change(screen.getByLabelText('Fecha y hora de inicio *'), { target: { value: '2026-06-01T19:00' } })
    fireEvent.click(screen.getByRole('button', { name: /Subir archivo/ }))
    fireEvent.click(screen.getByRole('button', { name: 'Enviar evento' }))
    expect(await screen.findByRole('button', { name: 'Enviando...' })).toBeDisabled()
    expect(vi.mocked(eventsApi.createArtistEvent).mock.calls[0][0]).toMatchObject({ flyer: undefined, image_url: undefined })
    expect(toast.success).not.toHaveBeenCalled()
  })
})
