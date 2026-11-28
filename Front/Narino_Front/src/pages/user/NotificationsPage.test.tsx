import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

import {
  getUnreadNotificationsCount,
  listNotifications,
  markAllNotificationsRead,
  markNotificationRead,
} from '@/api/notifications.api'
import NotificationsPage from '@/pages/user/NotificationsPage'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'
import type { AppNotification, PaginatedResponse } from '@/types'

vi.mock('@/api/notifications.api', () => ({
  listNotifications: vi.fn(),
  getUnreadNotificationsCount: vi.fn(),
  markNotificationRead: vi.fn(),
  markAllNotificationsRead: vi.fn(),
}))

const mockedList = vi.mocked(listNotifications)
const mockedUnread = vi.mocked(getUnreadNotificationsCount)
const mockedMarkRead = vi.mocked(markNotificationRead)
const mockedMarkAll = vi.mocked(markAllNotificationsRead)

function notification(overrides: Partial<AppNotification>): AppNotification {
  return {
    id: 'n1',
    type: 'EVENT_REMINDER',
    title: 'Tu evento está por empezar',
    body: '«Concierto andino» empieza mañana.',
    data: { url: '/events/e1' },
    read: false,
    read_at: null,
    created_at: new Date(Date.now() - 5 * 60 * 1000).toISOString(),
    ...overrides,
  }
}

function page(results: AppNotification[], next: string | null = null): PaginatedResponse<AppNotification> {
  return { count: results.length, next, previous: null, results }
}

const SIN_LEER = notification({})
const LEIDA = notification({
  id: 'n2',
  type: 'PAYMENT_WEBHOOK',
  title: 'Pago confirmado',
  body: 'Recibimos tu pago.',
  data: { url: '/orders' },
  read: true,
  read_at: '2026-11-20T10:00:00Z',
  created_at: new Date(Date.now() - 3 * 3600 * 1000).toISOString(),
})

function renderPage() {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={['/notifications']}>
        <Routes>
          <Route path="/notifications" element={<NotificationsPage />} />
          <Route path="/events/:id" element={<p>Detalle del evento</p>} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('NotificationsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ isAuthenticated: true, accessToken: 'token', refreshToken: 'refresh' })
    mockedUnread.mockResolvedValue(1)
    mockedList.mockImplementation(async (params) =>
      params?.unread ? page([SIN_LEER]) : page([SIN_LEER, LEIDA]),
    )
    mockedMarkRead.mockResolvedValue({ ...SIN_LEER, read: true })
    mockedMarkAll.mockResolvedValue(1)
  })

  it('muestra la bandeja con las sin leer marcadas y el tiempo relativo', async () => {
    renderPage()
    expect(await screen.findByText('Tu evento está por empezar')).toBeInTheDocument()
    expect(screen.getByText('Pago confirmado')).toBeInTheDocument()
    expect(screen.getByText('(sin leer)')).toBeInTheDocument()
    expect(screen.getByText('hace 5 minutos')).toBeInTheDocument()
    expect(screen.getByText('hace 3 horas')).toBeInTheDocument()
    expect(mockedList).toHaveBeenCalledWith({ unread: false, page: 1 })
  })

  it('filtra las no leídas', async () => {
    renderPage()
    await screen.findByText('Pago confirmado')
    fireEvent.click(await screen.findByRole('tab', { name: 'No leídas (1)' }))
    await waitFor(() => expect(mockedList).toHaveBeenLastCalledWith({ unread: true, page: 1 }))
    await waitFor(() => expect(screen.queryByText('Pago confirmado')).not.toBeInTheDocument())
  })

  it('al abrir un aviso lo marca como leído y lleva a su página', async () => {
    renderPage()
    fireEvent.click(await screen.findByText('Tu evento está por empezar'))
    await waitFor(() => expect(mockedMarkRead).toHaveBeenCalledWith('n1'))
    expect(await screen.findByText('Detalle del evento')).toBeInTheDocument()
  })

  it('un aviso ya leído no se vuelve a marcar, solo lleva a su enlace', async () => {
    renderWithProviders(<NotificationsPage />, { route: '/notifications', path: '/notifications' })
    fireEvent.click(await screen.findByText('Pago confirmado'))
    expect(mockedMarkRead).not.toHaveBeenCalled()
    expect(screen.getByTestId('location').textContent).toBe('/orders')
  })

  it('marca todas como leídas', async () => {
    renderPage()
    const boton = await screen.findByRole('button', { name: /marcar todas como leídas/i })
    await waitFor(() => expect(boton).toBeEnabled())
    fireEvent.click(boton)
    await waitFor(() => expect(mockedMarkAll).toHaveBeenCalled())
  })

  it('sin avisos sin leer no deja marcar todas', async () => {
    mockedUnread.mockResolvedValue(0)
    renderPage()
    await screen.findByText('Pago confirmado')
    expect(screen.getByRole('button', { name: /marcar todas como leídas/i })).toBeDisabled()
  })

  it('carga más avisos cuando hay otra página', async () => {
    const otra = notification({ id: 'n3', title: 'Te superaron en una subasta', read: true })
    mockedList.mockImplementation(async (params) =>
      params?.page === 2 ? page([otra]) : page([SIN_LEER], 'http://api/notifications/?page=2'),
    )
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: 'Cargar más' }))
    expect(await screen.findByText('Te superaron en una subasta')).toBeInTheDocument()
    expect(mockedList).toHaveBeenLastCalledWith({ unread: false, page: 2 })
  })

  it('muestra un estado vacío', async () => {
    mockedList.mockResolvedValue(page([]))
    renderPage()
    expect(await screen.findByText(/todavía no tienes notificaciones/i)).toBeInTheDocument()
  })

  it('permite reintentar si falla la carga', async () => {
    mockedList.mockRejectedValueOnce(new Error('sin red'))
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: 'Reintentar' }))
    expect(await screen.findByText('Tu evento está por empezar')).toBeInTheDocument()
  })
})
