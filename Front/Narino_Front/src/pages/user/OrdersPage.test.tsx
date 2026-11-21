import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

import { getOrders } from '@/api/marketplace.api'
import OrdersPage from '@/pages/user/OrdersPage'
import type { Order } from '@/types'

vi.mock('@/api/marketplace.api', () => ({ getOrders: vi.fn() }))
vi.mock('@/hooks/useStartPayment', () => ({
  useStartPayment: () => ({ mutate: vi.fn(), isPending: false, variables: undefined }),
}))

const mockedGetOrders = vi.mocked(getOrders)
const HOUR = 3600 * 1000

function order(overrides: Partial<Order>): Order {
  return {
    id: 'a1b2c3d4-0000-0000-0000-000000000000',
    buyer: 'u1',
    total_amount: '150000.00',
    status: 'PENDIENTE',
    order_type: 'COMPRA_DIRECTA',
    payment_due_at: null,
    items: [{ id: 'i1', artwork: 'w1', artwork_title: 'Volcán Galeras', price: '150000.00' }],
    payment: null,
    created_at: '2026-11-21T10:00:00-05:00',
    ...overrides,
  }
}

function renderPage() {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <OrdersPage />
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('OrdersPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('una compra pendiente muestra hasta cuándo se puede pagar', async () => {
    mockedGetOrders.mockResolvedValue([
      order({ payment_due_at: new Date(Date.now() + HOUR).toISOString() }),
    ])
    renderPage()
    expect(await screen.findByText(/paga antes del .* o las obras volverán al catálogo/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /pagar ahora/i })).toBeInTheDocument()
  })

  it('con el plazo vencido no deja pagar y explica qué pasó', async () => {
    mockedGetOrders.mockResolvedValue([
      order({ payment_due_at: new Date(Date.now() - HOUR).toISOString() }),
    ])
    renderPage()
    expect(await screen.findByText(/el plazo para pagar venció/i)).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /pagar ahora/i })).not.toBeInTheDocument()
  })

  it('una compra pagada muestra el medio de pago y el comprobante de Wompi', async () => {
    mockedGetOrders.mockResolvedValue([
      order({
        status: 'PAGADO',
        payment: {
          transaction_id: 't1',
          status: 'APROBADO',
          payment_method: 'CARD',
          receipt_url: 'https://comprobantes.wompi.test/r/1',
          updated_at: '2026-11-21T10:05:00-05:00',
        },
      }),
    ])
    renderPage()
    expect(await screen.findByText('Pagado con tarjeta')).toBeInTheDocument()
    const link = screen.getByRole('link', { name: /ver comprobante/i })
    expect(link).toHaveAttribute('href', 'https://comprobantes.wompi.test/r/1')
    expect(link).toHaveAttribute('target', '_blank')
    expect(link).toHaveAttribute('rel', 'noopener noreferrer')
  })

  it('sin comprobante todavía no muestra el enlace', async () => {
    mockedGetOrders.mockResolvedValue([
      order({
        status: 'PAGADO',
        payment: { transaction_id: 't1', status: 'APROBADO', payment_method: 'PSE', receipt_url: '', updated_at: '' },
      }),
    ])
    renderPage()
    expect(await screen.findByText('Pagado con PSE')).toBeInTheDocument()
    expect(screen.queryByRole('link', { name: /ver comprobante/i })).not.toBeInTheDocument()
  })
})
