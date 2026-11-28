import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'

import { getOrders } from '@/api/marketplace.api'
import { listNotifications, markAllNotificationsRead, markNotificationRead } from '@/api/notifications.api'
import NotificationsPage from '@/pages/user/NotificationsPage'
import OrdersPage from '@/pages/user/OrdersPage'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'
import type { AppNotification, Order } from '@/types'

const payment = vi.hoisted(() => ({ mutate: vi.fn(), isPending: false, variables: undefined as string | undefined }))

vi.mock('@/api/marketplace.api', () => ({ getOrders: vi.fn() }))
vi.mock('@/api/notifications.api', () => ({
  listNotifications: vi.fn(),
  markNotificationRead: vi.fn(),
  markAllNotificationsRead: vi.fn(),
  getUnreadNotificationsCount: vi.fn().mockResolvedValue(2),
}))
vi.mock('@/hooks/useStartPayment', () => ({ useStartPayment: () => payment }))

const mockedOrders = vi.mocked(getOrders)

function order(overrides: Partial<Order> = {}): Order {
  return {
    id: 'a1b2c3d4-0000',
    buyer: 'u1',
    total_amount: '150000.00',
    status: 'PENDIENTE',
    order_type: 'COMPRA_DIRECTA',
    payment_due_at: new Date(Date.now() + 3600_000).toISOString(),
    items: [{ id: 'i1', artwork: 'w1', artwork_title: 'Volcán', price: '150000' }],
    payment: null,
    created_at: '2026-11-21T10:00:00-05:00',
    ...overrides,
  }
}

describe('OrdersPage: casos de borde', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    payment.isPending = false
    payment.variables = undefined
  })

  it('muestra esqueletos al cargar y el vacío sin pedidos', async () => {
    mockedOrders.mockResolvedValue([])
    const { container } = renderWithProviders(<OrdersPage />)
    expect(container.querySelectorAll('.animate-pulse')).toHaveLength(3)
    expect(await screen.findByText('Aún no has realizado ningún pedido.')).toBeInTheDocument()
  })

  it('"Pagar ahora" inicia el pago de esa orden; mientras abre el pago lo indica', async () => {
    mockedOrders.mockResolvedValue([order()])
    const { unmount } = renderWithProviders(<OrdersPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Pagar ahora/ }))
    expect(payment.mutate).toHaveBeenCalledWith('a1b2c3d4-0000')
    unmount()

    payment.isPending = true
    payment.variables = 'a1b2c3d4-0000'
    renderWithProviders(<OrdersPage />)
    expect(await screen.findByRole('button', { name: /Abriendo pago…/ })).toBeDisabled()
  })

  it('con el pago abierto para otra orden este botón sigue diciendo "Pagar ahora" pero bloqueado', async () => {
    mockedOrders.mockResolvedValue([order()])
    payment.isPending = true
    payment.variables = 'otra-orden'
    renderWithProviders(<OrdersPage />)
    expect(await screen.findByRole('button', { name: /Pagar ahora/ })).toBeDisabled()
  })

  it('tolera estado, tipo y medio de pago desconocidos, obras sin título y singular/plural', async () => {
    mockedOrders.mockResolvedValue([
      order({
        id: 'unica-0000',
        status: 'RARO' as Order['status'],
        order_type: 'OTRO' as Order['order_type'],
        payment_due_at: null,
        items: [{ id: 'i1', artwork: 'w1', price: '1000' }],
      }),
      order({
        id: 'pagada-000',
        status: 'PAGADO',
        payment_due_at: null,
        payment: { transaction_id: 't', status: 'APROBADO', payment_method: 'CRIPTO', receipt_url: 'https://wompi.test/r', updated_at: '' },
        items: [
          { id: 'i1', artwork: 'w1', artwork_title: 'Uno', price: '1' },
          { id: 'i2', artwork: 'w2', artwork_title: 'Dos', price: '2' },
        ],
      }),
    ])
    renderWithProviders(<OrdersPage />)
    expect(await screen.findByText('RARO')).toBeInTheDocument()
    expect(screen.getByText('OTRO')).toBeInTheDocument()
    expect(screen.getByText('Obra')).toBeInTheDocument()
    expect(screen.getByText('1 obra')).toBeInTheDocument()
    expect(screen.getByText('2 obras')).toBeInTheDocument()
    expect(screen.getByText('Pagado con CRIPTO')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /Ver comprobante/ })).toHaveAttribute('href', 'https://wompi.test/r')
  })

  it('un pedido sin obras no muestra el bloque de obras', async () => {
    mockedOrders.mockResolvedValue([order({ items: [] })])
    renderWithProviders(<OrdersPage />)
    await screen.findByText('#A1B2C3D4')
    expect(screen.queryByText(/obras?$/)).not.toBeInTheDocument()
  })
})

const mockedList = vi.mocked(listNotifications)
const mockedRead = vi.mocked(markNotificationRead)
const mockedReadAll = vi.mocked(markAllNotificationsRead)

function note(id: string, overrides: Partial<AppNotification> = {}): AppNotification {
  return {
    id, type: 'X', title: `Aviso ${id}`, body: 'Cuerpo', data: { url: '/orders' }, read: false, read_at: null,
    created_at: new Date().toISOString(), ...overrides,
  }
}
const page = (results: AppNotification[], next: string | null = null) => ({ count: results.length, next, previous: null, results })

describe('NotificationsPage: casos de borde', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ isAuthenticated: true })
  })

  function renderPage() {
    return renderWithProviders(<NotificationsPage />, { route: '/notifications', path: '/notifications' })
  }

  it('al abrir una no leída la marca y navega a su ruta interna', async () => {
    mockedList.mockResolvedValue(page([note('1')]))
    mockedRead.mockResolvedValue(note('1', { read: true }))
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Aviso 1/ }))
    await waitFor(() => expect(mockedRead.mock.calls[0][0]).toBe('1'))
    expect(screen.getByTestId('location')).toHaveTextContent('/orders')
  })

  it.each([
    ['sin url', {}],
    ['url externa', { url: 'https://malo.test' }],
    ['url con doble barra', { url: '//malo.test' }],
    ['url que no es texto', { url: 42 } as unknown as { url: string }],
  ])('una notificación leída %s no navega', async (_name, data) => {
    mockedList.mockResolvedValue(page([note('2', { read: true, data })]))
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Aviso 2/ }))
    expect(mockedRead).not.toHaveBeenCalled()
    expect(screen.getByTestId('location')).toHaveTextContent('/notifications')
  })

  it('sin notificaciones sin leer lo indica; en "Todas" muestra el otro texto', async () => {
    mockedList.mockResolvedValue(page([]))
    renderPage()
    expect(await screen.findByText(/Todavía no tienes notificaciones/)).toBeInTheDocument()
    fireEvent.click(screen.getByRole('tab', { name: /No leídas/ }))
    expect(await screen.findByText('No tienes notificaciones sin leer.')).toBeInTheDocument()
    expect(mockedList).toHaveBeenLastCalledWith({ unread: true, page: 1 })
  })

  it('"Cargar más" pide la siguiente página y mientras tanto dice "Cargando…"', async () => {
    mockedList.mockResolvedValueOnce(page([note('1', { read: true })], 'siguiente'))
    renderPage()
    await screen.findByText('Aviso 1')
    let resolveNext!: (v: ReturnType<typeof page>) => void
    mockedList.mockReturnValueOnce(new Promise((r) => { resolveNext = r }) as never)
    fireEvent.click(screen.getByRole('button', { name: 'Cargar más' }))
    expect(await screen.findByRole('button', { name: 'Cargando…' })).toBeDisabled()
    resolveNext(page([note('2', { read: true })]))
    expect(await screen.findByText('Aviso 2')).toBeInTheDocument()
    expect(mockedList).toHaveBeenLastCalledWith({ unread: false, page: 2 })
    expect(screen.queryByRole('button', { name: 'Cargar más' })).not.toBeInTheDocument()
  })

  it('"Marcar todas como leídas" avisa al servidor', async () => {
    mockedList.mockResolvedValue(page([note('1')]))
    mockedReadAll.mockResolvedValue(1)
    renderPage()
    await screen.findByText('Aviso 1')
    await waitFor(() => expect(screen.getByRole('button', { name: /Marcar todas como leídas/ })).toBeEnabled())
    fireEvent.click(screen.getByRole('button', { name: /Marcar todas como leídas/ }))
    await waitFor(() => expect(mockedReadAll).toHaveBeenCalled())
  })

  it('si no cargan permite reintentar', async () => {
    mockedList.mockRejectedValueOnce(new Error('x'))
    renderPage()
    expect(await screen.findByText('No pudimos cargar tus notificaciones.')).toBeInTheDocument()
    mockedList.mockResolvedValueOnce(page([note('3', { read: true })]))
    fireEvent.click(screen.getByRole('button', { name: 'Reintentar' }))
    expect(await screen.findByText('Aviso 3')).toBeInTheDocument()
  })
})
