import { describe, it, expect, vi, beforeEach } from 'vitest'
import { screen } from '@testing-library/react'

import { getAdminTransactions, type AdminTransaction } from '@/api/admin.api'
import AdminTransactionsPage from '@/pages/admin/AdminTransactionsPage'
import { renderWithProviders } from '@/test/render'

vi.mock('@/api/admin.api', () => ({ getAdminTransactions: vi.fn() }))
const mockedGet = vi.mocked(getAdminTransactions)

function tx(overrides: Partial<AdminTransaction>): AdminTransaction {
  return {
    id: 't1',
    order_id: 'abcdef12-0000',
    buyer_email: 'comprador@test.com',
    amount: '150000.00',
    currency: 'COP',
    status: 'APROBADO',
    total_amount: '150000.00',
    order_type: 'COMPRA_DIRECTA',
    order_status: 'PAGADA',
    created_at: '2026-03-05T12:00:00Z',
    ...overrides,
  }
}

describe('AdminTransactionsPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('muestra esqueletos y luego la tabla con orden, comprador, tipo, monto, estado y fecha', async () => {
    mockedGet.mockResolvedValue([
      tx({}),
      tx({ id: 't2', order_type: 'SUBASTA', status: 'PENDIENTE', created_at: '' }),
      tx({ id: 't3', status: 'DESCONOCIDO' as AdminTransaction['status'] }),
    ])
    const { container } = renderWithProviders(<AdminTransactionsPage />)
    expect(container.querySelectorAll('.animate-pulse')).toHaveLength(5)
    expect(await screen.findAllByText('#ABCDEF12')).toHaveLength(3)
    expect(screen.getAllByText('comprador@test.com')).toHaveLength(3)
    expect(screen.getAllByText('Directa')).toHaveLength(2)
    expect(screen.getByText('Subasta')).toBeInTheDocument()
    expect(screen.getAllByText(/150\.000/)).toHaveLength(3)
    expect(screen.getByText('Aprobado')).toBeInTheDocument()
    expect(screen.getByText('Pendiente')).toBeInTheDocument()
    expect(screen.getByText('DESCONOCIDO')).toBeInTheDocument()
    expect(screen.getAllByText(/2026/)).toHaveLength(2)
    expect(screen.getByText('—')).toBeInTheDocument()
    expect(screen.getByRole('columnheader', { name: 'Comprador' })).toBeInTheDocument()
  })

  it('sin transacciones muestra el vacío', async () => {
    mockedGet.mockResolvedValue([])
    renderWithProviders(<AdminTransactionsPage />)
    expect(await screen.findByText('No hay transacciones registradas.')).toBeInTheDocument()
  })
})
