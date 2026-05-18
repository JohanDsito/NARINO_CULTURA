import { Suspense, lazy, type ComponentType } from 'react'
import { createBrowserRouter, Navigate } from 'react-router-dom'

import { AppLayout } from '@/components/layout/app-layout'
import { ProtectedRoute } from '@/components/auth/protected-route'
import { PageLoader } from '@/components/layout/page-loader'
import { ANY_AUTH, ROLE } from '@/constants/roles'
import UnderConstructionPage from '@/pages/Shared/UnderConstructionPage'

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
      { index: true, element: lazyPage(() => import('@/pages/Home/HomePage'), 'Cargando inicio…') },

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
        element: lazyPage(
          () => import('@/pages/Auth/ForgotPasswordPage'),
          'Cargando recuperación…',
        ),
      },
      {
        path: 'reset-password',
        element: (
          <UnderConstructionPage
            title="Restablecer contraseña"
            description="Formulario para crear una nueva contraseña."
          />
        ),
      },

      {
        path: 'artists',
        element: (
          <UnderConstructionPage
            title="Artistas"
            description="Directorio de artistas con filtros, búsqueda y paginación infinita."
          />
        ),
      },
      {
        path: 'artists/:slug',
        element: (
          <UnderConstructionPage
            title="Perfil de artista"
            description="Banner, bio, seguidores, portafolio y obras del artista."
          />
        ),
      },

      {
        path: 'artworks',
        element: (
          <UnderConstructionPage
            title="Obras"
            description="Catálogo con filtros, ordenamiento y vista grid/lista."
          />
        ),
      },
      {
        path: 'artworks/:id',
        element: (
          <UnderConstructionPage
            title="Detalle de obra"
            description="Galería, información y acciones: carrito o subasta."
          />
        ),
      },

      {
        path: 'marketplace',
        element: (
          <UnderConstructionPage
            title="Marketplace"
            description="Explora novedades, más vendidos y artistas destacados."
          />
        ),
      },
      {
        path: 'auctions',
        element: (
          <UnderConstructionPage
            title="Subastas"
            description="Subastas activas, próximas y finalizadas con countdown."
          />
        ),
      },
      {
        path: 'auctions/:id',
        element: (
          <UnderConstructionPage
            title="Sala de subasta"
            description="Puja en tiempo real con WebSocket, historial y participantes."
          />
        ),
      },
      {
        path: 'events',
        element: (
          <UnderConstructionPage
            title="Eventos"
            description="Agenda cultural con vista calendario y lista."
          />
        ),
      },
      {
        path: 'events/:id',
        element: (
          <UnderConstructionPage
            title="Detalle de evento"
            description="Información completa, mapa y registro de interés."
          />
        ),
      },

      {
        path: 'checkout',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            <UnderConstructionPage
              title="Checkout"
              description="Resumen de orden, datos de envío e integración Wompi."
            />
          </ProtectedRoute>
        ),
      },
      {
        path: 'orders',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            <UnderConstructionPage title="Mis pedidos" description="Historial de órdenes y estados." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'notifications',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            <UnderConstructionPage
              title="Notificaciones"
              description="Centro de notificaciones del usuario autenticado."
            />
          </ProtectedRoute>
        ),
      },
      {
        path: 'profile',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            <UnderConstructionPage title="Mi perfil" description="Preferencias, datos y seguridad." />
          </ProtectedRoute>
        ),
      },

      {
        path: 'payment/success',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            <UnderConstructionPage title="Pago exitoso" description="Resultado final de la transacción." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'payment/pending',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            <UnderConstructionPage title="Pago pendiente" description="La transacción está en proceso." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'payment/declined',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            <UnderConstructionPage title="Pago rechazado" description="La transacción no fue aprobada." />
          </ProtectedRoute>
        ),
      },

      {
        path: 'dashboard/profile',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            {lazyPage(() => import('@/pages/artist/ArtistDashboardPage'), 'Cargando perfil de artista...')}
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/artworks',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            <UnderConstructionPage title="Mis obras" description="Gestión de obras publicadas." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/artworks/new',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            <UnderConstructionPage title="Nueva obra" description="Formulario de publicación de obra." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/artworks/:id/edit',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            <UnderConstructionPage title="Editar obra" description="Formulario de edición de obra." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/sales',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            <UnderConstructionPage title="Ventas" description="Métricas y órdenes recibidas." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/analytics',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            <UnderConstructionPage title="Analítica" description="Panel analítico del artista." />
          </ProtectedRoute>
        ),
      },

      {
        path: 'admin',
        element: <Navigate to="/admin/dashboard" replace />,
      },
      {
        path: 'admin/dashboard',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.admin]}>
            <UnderConstructionPage
              title="Admin — Dashboard"
              description="Métricas, gráficos y actividad reciente."
            />
          </ProtectedRoute>
        ),
      },
      {
        path: 'admin/users',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.admin]}>
            <UnderConstructionPage title="Admin — Usuarios" description="Gestión de roles y estado." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'admin/artworks',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.admin]}>
            <UnderConstructionPage
              title="Admin — Moderación"
              description="Aprobar o rechazar obras pendientes."
            />
          </ProtectedRoute>
        ),
      },
      {
        path: 'admin/events',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.admin]}>
            <UnderConstructionPage title="Admin — Eventos" description="CRUD completo de eventos." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'admin/transactions',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.admin]}>
            <UnderConstructionPage
              title="Admin — Transacciones"
              description="Auditoría financiera y exportación CSV."
            />
          </ProtectedRoute>
        ),
      },

      { path: '*', element: lazyPage(() => import('@/pages/NotFound/NotFoundPage')) },
    ],
  },
])
