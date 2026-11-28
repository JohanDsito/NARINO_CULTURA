import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen } from '@testing-library/react'
import { RouterProvider, createMemoryRouter } from 'react-router-dom'

import { router } from '@/router'
import { useAuthStore } from '@/store/authStore'
import type { User } from '@/types'

// Cada página se sustituye por un marcador: aquí se prueba la tabla de rutas (cuál página abre cada URL
// y quién puede entrar), no las páginas, que tienen sus propias pruebas.
vi.mock('@/pages/admin/AdminArtworksPage', () => ({ default: () => <div>pagina:AdminArtworksPage</div> }))
vi.mock('@/pages/admin/AdminDashboardPage', () => ({ default: () => <div>pagina:AdminDashboardPage</div> }))
vi.mock('@/pages/admin/AdminEventsPage', () => ({ default: () => <div>pagina:AdminEventsPage</div> }))
vi.mock('@/pages/admin/AdminTransactionsPage', () => ({ default: () => <div>pagina:AdminTransactionsPage</div> }))
vi.mock('@/pages/admin/AdminUsersPage', () => ({ default: () => <div>pagina:AdminUsersPage</div> }))
vi.mock('@/pages/artist/ArtistAnalyticsPage', () => ({ default: () => <div>pagina:ArtistAnalyticsPage</div> }))
vi.mock('@/pages/artist/ArtistArtworksPage', () => ({ default: () => <div>pagina:ArtistArtworksPage</div> }))
vi.mock('@/pages/artist/ArtistDashboardPage', () => ({ default: () => <div>pagina:ArtistDashboardPage</div> }))
vi.mock('@/pages/artist/ArtistProfilePage', () => ({ default: () => <div>pagina:ArtistProfilePage</div> }))
vi.mock('@/pages/artist/ArtistRoleSelectPage', () => ({ default: () => <div>pagina:ArtistRoleSelectPage</div> }))
vi.mock('@/pages/artist/ArtworkCreatePage', () => ({ default: () => <div>pagina:ArtworkCreatePage</div> }))
vi.mock('@/pages/artist/ArtworkEditPage', () => ({ default: () => <div>pagina:ArtworkEditPage</div> }))
vi.mock('@/pages/artists/ArtistsPage', () => ({ default: () => <div>pagina:ArtistsPage</div> }))
vi.mock('@/pages/artworks/ArtworkDetailPage', () => ({ default: () => <div>pagina:ArtworkDetailPage</div> }))
vi.mock('@/pages/artworks/ArtworksCatalogPage', () => ({ default: () => <div>pagina:ArtworksCatalogPage</div> }))
vi.mock('@/pages/auctions/AuctionRoomPage', () => ({ default: () => <div>pagina:AuctionRoomPage</div> }))
vi.mock('@/pages/auctions/AuctionsPage', () => ({ default: () => <div>pagina:AuctionsPage</div> }))
vi.mock('@/pages/auth/ForgotPasswordPage', () => ({ default: () => <div>pagina:ForgotPasswordPage</div> }))
vi.mock('@/pages/auth/LoginPage', () => ({ default: () => <div>pagina:LoginPage</div> }))
vi.mock('@/pages/auth/RegisterPage', () => ({ default: () => <div>pagina:RegisterPage</div> }))
vi.mock('@/pages/auth/ResetPasswordPage', () => ({ default: () => <div>pagina:ResetPasswordPage</div> }))
vi.mock('@/pages/auth/VerifyEmailPage', () => ({ default: () => <div>pagina:VerifyEmailPage</div> }))
vi.mock('@/pages/checkout/CheckoutPage', () => ({ default: () => <div>pagina:CheckoutPage</div> }))
vi.mock('@/pages/events/ArtistEventCreatePage', () => ({ default: () => <div>pagina:ArtistEventCreatePage</div> }))
vi.mock('@/pages/events/EventDetailPage', () => ({ default: () => <div>pagina:EventDetailPage</div> }))
vi.mock('@/pages/events/EventsPage', () => ({ default: () => <div>pagina:EventsPage</div> }))
vi.mock('@/pages/home/HomePage', () => ({ default: () => <div>pagina:HomePage</div> }))
vi.mock('@/pages/marketplace/MarketplacePage', () => ({ default: () => <div>pagina:MarketplacePage</div> }))
vi.mock('@/pages/musicians/MusicDiscoveryPage', () => ({ default: () => <div>pagina:MusicDiscoveryPage</div> }))
vi.mock('@/pages/musicians/MusicianDashboardPage', () => ({ default: () => <div>pagina:MusicianDashboardPage</div> }))
vi.mock('@/pages/musicians/MusicianDirectoryPage', () => ({ default: () => <div>pagina:MusicianDirectoryPage</div> }))
vi.mock('@/pages/musicians/MusicianProfilePage', () => ({ default: () => <div>pagina:MusicianProfilePage</div> }))
vi.mock('@/pages/musicians/MusicianWorkCreatePage', () => ({ default: () => <div>pagina:MusicianWorkCreatePage</div> }))
vi.mock('@/pages/musicians/MusicianWorkEditPage', () => ({ default: () => <div>pagina:MusicianWorkEditPage</div> }))
vi.mock('@/pages/musicians/MusicianWorksPage', () => ({ default: () => <div>pagina:MusicianWorksPage</div> }))
vi.mock('@/pages/not-found/NotFoundPage', () => ({ default: () => <div>pagina:NotFoundPage</div> }))
vi.mock('@/pages/payment/PaymentDeclinedPage', () => ({ default: () => <div>pagina:PaymentDeclinedPage</div> }))
vi.mock('@/pages/payment/PaymentPendingPage', () => ({ default: () => <div>pagina:PaymentPendingPage</div> }))
vi.mock('@/pages/payment/PaymentSuccessPage', () => ({ default: () => <div>pagina:PaymentSuccessPage</div> }))
vi.mock('@/pages/user/FavoritesPage', () => ({ default: () => <div>pagina:FavoritesPage</div> }))
vi.mock('@/pages/user/NotificationsPage', () => ({ default: () => <div>pagina:NotificationsPage</div> }))
vi.mock('@/pages/user/OrdersPage', () => ({ default: () => <div>pagina:OrdersPage</div> }))
vi.mock('@/pages/user/UserProfilePage', () => ({ default: () => <div>pagina:UserProfilePage</div> }))
vi.mock('@/components/layout/app-layout', async () => {
  const { Outlet } = await import('react-router-dom')
  return { AppLayout: () => <Outlet /> }
})

type Access = 'none' | 'any' | 'artist' | 'admin'

// [url, página que debe abrir, quién puede entrar]
const ROUTES: [string, string, Access][] = [
  ['/', 'HomePage', 'none'],
  ['/login', 'LoginPage', 'none'],
  ['/register', 'RegisterPage', 'none'],
  ['/verify-email', 'VerifyEmailPage', 'none'],
  ['/forgot-password', 'ForgotPasswordPage', 'none'],
  ['/reset-password', 'ResetPasswordPage', 'none'],
  ['/artists', 'ArtistsPage', 'none'],
  ['/artists/demo', 'ArtistProfilePage', 'none'],
  ['/artworks', 'ArtworksCatalogPage', 'none'],
  ['/artworks/7', 'ArtworkDetailPage', 'none'],
  ['/musicians', 'MusicianDirectoryPage', 'none'],
  ['/musicians/demo', 'MusicianProfilePage', 'none'],
  ['/music-discovery', 'MusicDiscoveryPage', 'none'],
  ['/marketplace', 'MarketplacePage', 'none'],
  ['/auctions', 'AuctionsPage', 'none'],
  ['/auctions/7', 'AuctionRoomPage', 'any'],
  ['/events', 'EventsPage', 'none'],
  ['/events/7', 'EventDetailPage', 'none'],
  ['/checkout', 'CheckoutPage', 'any'],
  ['/orders', 'OrdersPage', 'any'],
  ['/favorites', 'FavoritesPage', 'any'],
  ['/notifications', 'NotificationsPage', 'any'],
  ['/profile', 'UserProfilePage', 'any'],
  ['/payment/success', 'PaymentSuccessPage', 'any'],
  ['/payment/pending', 'PaymentPendingPage', 'any'],
  ['/payment/declined', 'PaymentDeclinedPage', 'any'],
  ['/dashboard', 'ArtistRoleSelectPage', 'artist'],
  ['/dashboard/profile', 'ArtistDashboardPage', 'artist'],
  ['/dashboard/artworks', 'ArtistArtworksPage', 'artist'],
  ['/dashboard/artworks/new', 'ArtworkCreatePage', 'artist'],
  ['/dashboard/artworks/7/edit', 'ArtworkEditPage', 'artist'],
  ['/dashboard/sales', 'ArtistAnalyticsPage', 'artist'],
  ['/dashboard/analytics', 'ArtistAnalyticsPage', 'artist'],
  ['/dashboard/events/new', 'ArtistEventCreatePage', 'artist'],
  ['/dashboard/musician/profile', 'MusicianDashboardPage', 'artist'],
  ['/dashboard/musician/works', 'MusicianWorksPage', 'artist'],
  ['/dashboard/musician/works/new', 'MusicianWorkCreatePage', 'artist'],
  ['/dashboard/musician/works/7/edit', 'MusicianWorkEditPage', 'artist'],
  ['/admin/dashboard', 'AdminDashboardPage', 'admin'],
  ['/admin/users', 'AdminUsersPage', 'admin'],
  ['/admin/artworks', 'AdminArtworksPage', 'admin'],
  ['/admin/events', 'AdminEventsPage', 'admin'],
  ['/admin/transactions', 'AdminTransactionsPage', 'admin'],
]

function renderAt(url: string) {
  const memory = createMemoryRouter(router.routes, { initialEntries: [url] })
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={memory} />
    </QueryClientProvider>,
  )
}

function signIn(role: User['role']) {
  useAuthStore.setState({ accessToken: 't', refreshToken: 'r', isAuthenticated: true, user: { id: 'u1', role } as User })
}

describe('router', () => {
  beforeEach(() => {
    useAuthStore.setState({ accessToken: null, refreshToken: null, isAuthenticated: false, user: null })
  })

  it.each(ROUTES.filter(([, , access]) => access === 'none'))('%s es pública y abre %s', async (url, page) => {
    renderAt(url)
    expect(await screen.findByText(`pagina:${page}`)).toBeInTheDocument()
  })

  it.each(ROUTES.filter(([, , access]) => access === 'any' || access === 'artist'))(
    '%s abre %s para una artista con sesión',
    async (url, page) => {
      signIn('artist')
      renderAt(url)
      expect(await screen.findByText(`pagina:${page}`)).toBeInTheDocument()
    },
  )

  it.each(ROUTES.filter(([, , access]) => access === 'any' || access === 'admin'))(
    '%s abre %s para un administrador',
    async (url, page) => {
      signIn('admin')
      renderAt(url)
      expect(await screen.findByText(`pagina:${page}`)).toBeInTheDocument()
    },
  )

  it.each(ROUTES.filter(([, , access]) => access !== 'none'))('%s sin sesión lleva al login', async (url) => {
    renderAt(url)
    expect(await screen.findByText('pagina:LoginPage')).toBeInTheDocument()
  })

  it('un comprador no entra al panel de artista ni al de administración', async () => {
    signIn('buyer')
    renderAt('/dashboard/artworks')
    expect(await screen.findByText('pagina:HomePage')).toBeInTheDocument()
    renderAt('/admin/users')
    expect((await screen.findAllByText('pagina:HomePage')).length).toBeGreaterThan(0)
  })

  it('/admin redirige al panel de administración', async () => {
    signIn('admin')
    renderAt('/admin')
    expect(await screen.findByText('pagina:AdminDashboardPage')).toBeInTheDocument()
  })

  it('una URL desconocida abre la página 404', async () => {
    renderAt('/no-existe/para/nada')
    expect(await screen.findByText('pagina:NotFoundPage')).toBeInTheDocument()
  })
})
