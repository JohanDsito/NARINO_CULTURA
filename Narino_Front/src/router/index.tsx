import { Suspense, lazy, type ComponentType } from 'react'
import { createBrowserRouter, Navigate } from 'react-router-dom'

import { AppLayout } from '@/components/layout/app-layout'
import { ProtectedRoute } from '@/components/auth/protected-route'
import { PageLoader } from '@/components/layout/page-loader'
import { ANY_AUTH, ROLE } from '@/constants/roles'

function lazyPage<T extends { default: ComponentType }>(
  importer: () => Promise<T>,
  label?: string,
) {
  const Component = lazy(importer)
  return (
    <Suspense fallback={<PageLoader label={label ?? 'Cargando…'} />}>
      <Component />
    </Suspense>
  )
}

export const router = createBrowserRouter([
  {
    path: '/',
    element: <AppLayout />,
    children: [
      // ── Inicio ───────────────────────────────────────────────────────────
      {
        index: true,
        element: lazyPage(() => import('@/pages/Home/HomePage'), 'Cargando inicio…'),
      },

      // ── Auth ─────────────────────────────────────────────────────────────
      {
        path: 'login',
        element: lazyPage(() => import('@/pages/Auth/LoginPage'), 'Cargando login…'),
      },
      {
        path: 'register',
        element: lazyPage(() => import('@/pages/Auth/RegisterPage'), 'Cargando registro…'),
      },
      {
        path: 'verify-email',
        element: lazyPage(() => import('@/pages/Auth/VerifyEmailPage'), 'Verificando correo…'),
      },
      {
        path: 'forgot-password',
        element: lazyPage(() => import('@/pages/Auth/ForgotPasswordPage'), 'Cargando recuperación…'),
      },
      {
        path: 'reset-password',
        element: lazyPage(() => import('@/pages/Auth/ResetPasswordPage'), 'Restableciendo contraseña…'),
      },

      // ── Artistas ──────────────────────────────────────────────────────────
      {
        path: 'artists',
        element: lazyPage(() => import('@/pages/artists/ArtistsPage'), 'Cargando artistas…'),
      },
      {
        path: 'artists/:slug',
        element: lazyPage(() => import('@/pages/artist/ArtistProfilePage'), 'Cargando perfil…'),
      },

      // ── Obras ─────────────────────────────────────────────────────────────
      {
        path: 'artworks',
        element: lazyPage(() => import('@/pages/artworks/ArtworksCatalogPage'), 'Cargando catálogo…'),
      },
      {
        path: 'artworks/:id',
        element: lazyPage(() => import('@/pages/artworks/ArtworkDetailPage'), 'Cargando obra…'),
      },

      // ── Músicos ───────────────────────────────────────────────────────────
      {
        path: 'musicians',
        element: lazyPage(() => import('@/pages/musicians/MusicianDirectoryPage'), 'Cargando músicos…'),
      },
      {
        path: 'musicians/:slug',
        element: lazyPage(() => import('@/pages/musicians/MusicianProfilePage'), 'Cargando perfil…'),
      },
      {
        path: 'music-discovery',
        element: lazyPage(() => import('@/pages/musicians/MusicDiscoveryPage'), 'Cargando descubrimiento…'),
      },

      // ── Marketplace ───────────────────────────────────────────────────────
      {
        path: 'marketplace',
        element: lazyPage(() => import('@/pages/marketplace/MarketplacePage'), 'Cargando marketplace…'),
      },

      // ── Subastas ──────────────────────────────────────────────────────────
      {
        path: 'auctions',
        element: lazyPage(() => import('@/pages/auctions/AuctionsPage'), 'Cargando subastas…'),
      },
      {
        path: 'auctions/:id',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            {lazyPage(() => import('@/pages/auctions/AuctionRoomPage'), 'Entrando a la sala…')}
          </ProtectedRoute>
        ),
      },

      // ── Eventos ───────────────────────────────────────────────────────────
      {
        path: 'events',
        element: lazyPage(() => import('@/pages/events/EventsPage'), 'Cargando eventos…'),
      },
      {
        path: 'events/:id',
        element: lazyPage(() => import('@/pages/events/EventDetailPage'), 'Cargando evento…'),
      },

      // ── Rutas protegidas (cualquier usuario autenticado) ──────────────────
      {
        path: 'checkout',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            {lazyPage(() => import('@/pages/checkout/CheckoutPage'), 'Cargando checkout…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'orders',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            {lazyPage(() => import('@/pages/user/OrdersPage'), 'Cargando pedidos…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'notifications',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            {lazyPage(() => import('@/pages/user/NotificationsPage'), 'Cargando notificaciones…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'profile',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            {lazyPage(() => import('@/pages/user/UserProfilePage'), 'Cargando perfil…')}
          </ProtectedRoute>
        ),
      },

      // ── Pagos ─────────────────────────────────────────────────────────────
      {
        path: 'payment/success',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            {lazyPage(() => import('@/pages/payment/PaymentSuccessPage'))}
          </ProtectedRoute>
        ),
      },
      {
        path: 'payment/pending',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            {lazyPage(() => import('@/pages/payment/PaymentPendingPage'))}
          </ProtectedRoute>
        ),
      },
      {
        path: 'payment/declined',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            {lazyPage(() => import('@/pages/payment/PaymentDeclinedPage'))}
          </ProtectedRoute>
        ),
      },

      // ── Dashboard del artista ─────────────────────────────────────────────
      {
        path: 'dashboard',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            {lazyPage(() => import('@/pages/artist/ArtistRoleSelectPage'), 'Cargando panel…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/profile',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            {lazyPage(() => import('@/pages/artist/ArtistDashboardPage'), 'Cargando dashboard…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/artworks',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            {lazyPage(() => import('@/pages/artist/ArtistArtworksPage'), 'Cargando mis obras…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/artworks/new',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            {lazyPage(() => import('@/pages/artist/ArtworkCreatePage'), 'Cargando nueva obra…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/artworks/:id/edit',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            {lazyPage(() => import('@/pages/artist/ArtworkEditPage'), 'Cargando edición…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/sales',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            {lazyPage(() => import('@/pages/artist/ArtistAnalyticsPage'), 'Cargando analítica…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/analytics',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            {lazyPage(() => import('@/pages/artist/ArtistAnalyticsPage'), 'Cargando analítica…')}
          </ProtectedRoute>
        ),
      },

      // ── Dashboard del músico ──────────────────────────────────────────────
      {
        path: 'dashboard/musician/profile',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            {lazyPage(() => import('@/pages/musicians/MusicianDashboardPage'), 'Cargando panel musical…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/musician/works',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            {lazyPage(() => import('@/pages/musicians/MusicianWorksPage'), 'Cargando obras…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/musician/works/new',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            {lazyPage(() => import('@/pages/musicians/MusicianWorkCreatePage'), 'Cargando formulario…')}
          </ProtectedRoute>
        ),
      },

      // ── Admin ─────────────────────────────────────────────────────────────
      {
        path: 'admin',
        element: <Navigate to="/admin/dashboard" replace />,
      },
      {
        path: 'admin/dashboard',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.admin]}>
            {lazyPage(() => import('@/pages/admin/AdminDashboardPage'), 'Cargando admin…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'admin/users',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.admin]}>
            {lazyPage(() => import('@/pages/admin/AdminUsersPage'), 'Cargando usuarios…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'admin/artworks',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.admin]}>
            {lazyPage(() => import('@/pages/admin/AdminArtworksPage'), 'Cargando moderación…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'admin/events',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.admin]}>
            {lazyPage(() => import('@/pages/admin/AdminEventsPage'), 'Cargando eventos…')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'admin/transactions',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.admin]}>
            {lazyPage(() => import('@/pages/admin/AdminTransactionsPage'), 'Cargando transacciones…')}
          </ProtectedRoute>
        ),
      },

      // ── 404 ───────────────────────────────────────────────────────────────
      { path: '*', element: lazyPage(() => import('@/pages/NotFound/NotFoundPage')) },
    ],
  },
])
