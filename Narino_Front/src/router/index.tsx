import { Suspense, lazy, type ComponentType } from 'react'
import { createBrowserRouter, Navigate } from 'react-router-dom'

import { ProtectedRoute } from '@/components/auth/protected-route'
import { AppLayout } from '@/components/layout/app-layout'
import { PageLoader } from '@/components/layout/page-loader'
import { ANY_AUTH, ROLE } from '@/constants/roles'
import UnderConstructionPage from '@/pages/Shared/UnderConstructionPage'

function lazyPage<T extends { default: ComponentType }>(
  importer: () => Promise<T>,
  label?: string,
) {
  const Component = lazy(importer)
  return (
    <Suspense fallback={<PageLoader label={label ?? 'Cargando...'} />}>
      <Component />
    </Suspense>
  )
}

export const router = createBrowserRouter([
  {
    path: '/',
    element: <AppLayout />,
    children: [
      { index: true, element: lazyPage(() => import('@/pages/Home/HomePage'), 'Cargando inicio...') },

      {
        path: 'login',
        element: lazyPage(() => import('@/pages/Auth/LoginPage'), 'Cargando login...'),
      },
      {
        path: 'register',
        element: lazyPage(() => import('@/pages/Auth/RegisterPage'), 'Cargando registro...'),
      },
      {
        path: 'forgot-password',
        element: lazyPage(
          () => import('@/pages/Auth/ForgotPasswordPage'),
          'Cargando recuperacion...',
        ),
      },
      {
        path: 'reset-password',
        element: lazyPage(
          () => import('@/pages/Auth/ResetPasswordPage'),
          'Cargando restablecimiento...',
        ),
      },
      {
        path: 'verify-email',
        element: lazyPage(
          () => import('@/pages/Auth/VerifyEmailPage'),
          'Cargando verificacion...',
        ),
      },

      {
        path: 'artists',
        element: (
          <UnderConstructionPage
            title="Artistas"
            description="Directorio de artistas con filtros, busqueda y paginacion infinita."
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
            description="Catalogo con filtros, ordenamiento y vista grid/lista."
          />
        ),
      },
      {
        path: 'artworks/:id',
        element: (
          <UnderConstructionPage
            title="Detalle de obra"
            description="Galeria, informacion y acciones: carrito o subasta."
          />
        ),
      },

      {
        path: 'marketplace',
        element: (
          <UnderConstructionPage
            title="Marketplace"
            description="Explora novedades, mas vendidos y artistas destacados."
          />
        ),
      },
      {
        path: 'auctions',
        element: (
          <UnderConstructionPage
            title="Subastas"
            description="Subastas activas, proximas y finalizadas con countdown."
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
            description="Informacion completa, mapa y registro de interes."
          />
        ),
      },

      {
        path: 'checkout',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            <UnderConstructionPage
              title="Checkout"
              description="Resumen de orden, datos de envio e integracion Wompi."
            />
          </ProtectedRoute>
        ),
      },
      {
        path: 'orders',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            <UnderConstructionPage title="Mis pedidos" description="Historial de ordenes y estados." />
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
            <UnderConstructionPage title="Pago exitoso" description="Resultado final de la transaccion." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'payment/pending',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            <UnderConstructionPage title="Pago pendiente" description="La transaccion esta en proceso." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'payment/declined',
        element: (
          <ProtectedRoute allowedRoles={ANY_AUTH}>
            <UnderConstructionPage title="Pago rechazado" description="La transaccion no fue aprobada." />
          </ProtectedRoute>
        ),
      },

      {
        path: 'dashboard/profile',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            <UnderConstructionPage
              title="Perfil de artista"
              description="Edicion de perfil, foto/banner y portafolio."
            />
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/artworks',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            <UnderConstructionPage title="Mis obras" description="Gestion de obras publicadas." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/artworks/new',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            <UnderConstructionPage title="Nueva obra" description="Formulario de publicacion de obra." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/artworks/:id/edit',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            <UnderConstructionPage title="Editar obra" description="Formulario de edicion de obra." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/sales',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            <UnderConstructionPage title="Ventas" description="Metricas y ordenes recibidas." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'dashboard/analytics',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.artist]}>
            <UnderConstructionPage title="Analitica" description="Panel analitico del artista." />
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
              title="Admin - Dashboard"
              description="Metricas, graficos y actividad reciente."
            />
          </ProtectedRoute>
        ),
      },
      {
        path: 'admin/users',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.admin]}>
            <UnderConstructionPage title="Admin - Usuarios" description="Gestion de roles y estado." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'admin/artworks',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.admin]}>
            <UnderConstructionPage
              title="Admin - Moderacion"
              description="Aprobar o rechazar obras pendientes."
            />
          </ProtectedRoute>
        ),
      },
      {
        path: 'admin/events',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.admin]}>
            <UnderConstructionPage title="Admin - Eventos" description="CRUD completo de eventos." />
          </ProtectedRoute>
        ),
      },
      {
        path: 'admin/transactions',
        element: (
          <ProtectedRoute allowedRoles={[ROLE.admin]}>
            <UnderConstructionPage
              title="Admin - Transacciones"
              description="Auditoria financiera y exportacion CSV."
            />
          </ProtectedRoute>
        ),
      },

      { path: '*', element: lazyPage(() => import('@/pages/NotFound/NotFoundPage')) },
    ],
  },
])
