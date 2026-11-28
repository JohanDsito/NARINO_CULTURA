import type { ReactNode } from 'react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { screen } from '@testing-library/react'

import { getSales } from '@/api/marketplace.api'
import ArtistAnalyticsPage from '@/pages/artist/ArtistAnalyticsPage'
import { renderWithProviders } from '@/test/render'
import type { Sale } from '@/types'

vi.mock('@/api/marketplace.api', () => ({ getSales: vi.fn() }))

// jsdom no mide el layout, así que recharts no dibuja nada: se sustituye por piezas simples que
// exponen los datos del gráfico y ejecutan los formateadores de ejes y tooltip.
vi.mock('recharts', () => ({
  ResponsiveContainer: ({ children }: { children: ReactNode }) => <div>{children}</div>,
  BarChart: ({ data, children }: { data: { month: string; total: number }[]; children: ReactNode }) => (
    <div data-testid="grafico">
      {data.map((d) => (
        <span key={d.month}>{`${d.month}=${d.total}`}</span>
      ))}
      {children}
    </div>
  ),
  Bar: () => null,
  XAxis: () => null,
  CartesianGrid: () => null,
  YAxis: ({ tickFormatter }: { tickFormatter: (v: number) => string }) => (
    <span data-testid="ejes">{`${tickFormatter(2_500_000)}|${tickFormatter(4000)}`}</span>
  ),
  Tooltip: ({ formatter }: { formatter: (v: number) => [string, string] }) => (
    <span data-testid="tooltip">{formatter(120000).join(':')}</span>
  ),
}))

const mockedSales = vi.mocked(getSales)

function sale(id: string, overrides: Partial<Record<string, string>> = {}): Sale {
  return {
    id,
    status: 'PAGADO',
    order_type: 'COMPRA_DIRECTA',
    seller_amount: '100000.00',
    created_at: '2026-03-10T10:00:00Z',
    ...overrides,
  } as unknown as Sale
}

describe('ArtistAnalyticsPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('muestra esqueletos mientras carga', () => {
    mockedSales.mockReturnValue(new Promise(() => {}))
    const { container } = renderWithProviders(<ArtistAnalyticsPage />)
    expect(container.querySelectorAll('.animate-pulse')).toHaveLength(3)
  })

  it('calcula ingresos, ventas completadas, promedio y agrupa por mes solo lo pagado', async () => {
    mockedSales.mockResolvedValue([
      sale('aaaaaaaa-1', { created_at: '2026-03-10T10:00:00Z', seller_amount: '100000' }),
      sale('bbbbbbbb-2', { created_at: '2026-03-20T10:00:00Z', seller_amount: '50000', order_type: 'SUBASTA' }),
      sale('cccccccc-3', { created_at: '2026-04-05T10:00:00Z', seller_amount: '30000' }),
      sale('dddddddd-4', { status: 'PENDIENTE', seller_amount: '999999' }),
      sale('eeeeeeee-5', { status: 'CANCELADO' }),
      sale('ffffffff-6', { status: 'REEMBOLSADO' }),
    ])
    renderWithProviders(<ArtistAnalyticsPage />)
    expect(await screen.findByText('Ingresos totales')).toBeInTheDocument()
    expect(screen.getByText('Ventas completadas').nextElementSibling).toHaveTextContent('3')
    expect(screen.getByText(/180\.000/, { selector: 'p.text-2xl' })).toBeInTheDocument()
    expect(screen.getByText(/60\.000/, { selector: 'p.text-2xl' })).toBeInTheDocument()
    expect(screen.getByText('mar 2026=150000')).toBeInTheDocument()
    expect(screen.getByText('abr 2026=30000')).toBeInTheDocument()
    expect(screen.getByTestId('ejes')).toHaveTextContent('2.5M|4K')
    expect(screen.getByTestId('tooltip')).toHaveTextContent(/120\.000:Ingresos/)
  })

  it('ventas recientes: en orden inverso, con tipo, estado y fecha', async () => {
    mockedSales.mockResolvedValue([sale('aaaaaaaa-1'), sale('bbbbbbbb-2', { status: 'CANCELADO', order_type: 'SUBASTA' }), sale('cccccccc-3', { status: 'PENDIENTE' })])
    renderWithProviders(<ArtistAnalyticsPage />)
    const rows = await screen.findAllByRole('row')
    expect(rows[1]).toHaveTextContent('#CCCCCCCC')
    expect(rows[1]).toHaveTextContent('PENDIENTE')
    expect(rows[2]).toHaveTextContent('Subasta')
    expect(rows[2]).toHaveTextContent('CANCELADO')
    expect(rows[3]).toHaveTextContent('Directa')
    expect(rows[3]).toHaveTextContent('mar 2026'.slice(0, 0) + '10 mar 2026')
  })

  it('solo muestra las 10 ventas más recientes y los últimos 6 meses', async () => {
    const months = ['01', '02', '03', '04', '05', '06', '07', '08']
    mockedSales.mockResolvedValue(
      months.map((m, i) => sale(`id${i}-xxxxxx`, { created_at: `2026-${m}-15T10:00:00Z`, seller_amount: '1000' })).concat(
        [sale('id8-xxxxxx'), sale('id9-xxxxxx'), sale('id10-xxxxx')],
      ),
    )
    renderWithProviders(<ArtistAnalyticsPage />)
    await screen.findByText('Ventas recientes')
    expect(screen.getAllByRole('row')).toHaveLength(11) // encabezado + 10
    expect(screen.queryByText(/ene 2026=/)).not.toBeInTheDocument()
  })

  it('sin ventas: promedio con guion y mensajes de vacío', async () => {
    mockedSales.mockResolvedValue([])
    renderWithProviders(<ArtistAnalyticsPage />)
    expect(await screen.findByText('No hay datos suficientes para mostrar el gráfico.')).toBeInTheDocument()
    expect(screen.getByText('Aún no tienes ventas registradas.')).toBeInTheDocument()
    expect(screen.getByText('Promedio por venta').nextElementSibling).toHaveTextContent('—')
  })
})
