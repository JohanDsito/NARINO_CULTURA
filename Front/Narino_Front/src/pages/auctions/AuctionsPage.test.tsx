import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'

import { getAuctions } from '@/api/auctions.api'
import AuctionsPage from '@/pages/auctions/AuctionsPage'
import { paginated } from '@/test/fixtures'
import { renderWithProviders } from '@/test/render'
import type { Auction, AuctionStatus } from '@/types'

vi.mock('@/api/auctions.api', () => ({ getAuctions: vi.fn() }))
const mockedGet = vi.mocked(getAuctions)

function makeAuction(id: string, status: AuctionStatus, base: string, current: string): Auction {
  return {
    id,
    artwork: 'a',
    seller: 's',
    base_price: base,
    current_price: current,
    highest_bidder: null,
    status,
    starts_at: '2026-01-01T00:00:00Z',
    ends_at: new Date(Date.now() + 3 * 24 * 3600 * 1000).toISOString(),
    winner: null,
    created_at: '',
    updated_at: '',
  }
}

describe('AuctionsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('lista las subastas en curso con precios, enlace y tiempo de cierre', async () => {
    mockedGet.mockResolvedValue(paginated([makeAuction('s1', 'ACTIVA', '100000', '250000')]))
    const { container } = renderWithProviders(<AuctionsPage />)
    expect(container.querySelectorAll('.animate-pulse')).toHaveLength(6)
    expect(await screen.findByText('En curso', { selector: 'span, div' })).toBeInTheDocument()
    expect(screen.getByText(/100\.000/)).toBeInTheDocument()
    expect(screen.getByText(/250\.000/)).toBeInTheDocument()
    expect(screen.getByText(/Cierra/)).toBeInTheDocument()
    expect(screen.getByRole('link')).toHaveAttribute('href', '/auctions/s1')
    expect(mockedGet).toHaveBeenCalledWith({ status: 'ACTIVA', page_size: 20 })
  })

  it('cambia de pestaña a finalizadas y canceladas con su etiqueta y sin hora de cierre', async () => {
    mockedGet.mockResolvedValue(paginated([]))
    renderWithProviders(<AuctionsPage />)
    expect(await screen.findByText('No hay subastas activas en este momento.')).toBeInTheDocument()

    mockedGet.mockResolvedValue([makeAuction('s2', 'CERRADA', '1000', '2000')])
    fireEvent.click(screen.getByRole('button', { name: 'Finalizadas' }))
    expect(await screen.findByText('Finalizada')).toBeInTheDocument()
    expect(mockedGet).toHaveBeenLastCalledWith({ status: 'CERRADA', page_size: 20 })
    expect(screen.queryByText(/Cierra/)).not.toBeInTheDocument()

    mockedGet.mockResolvedValue(paginated([makeAuction('s3', 'CANCELADA', '1000', '2000')]))
    fireEvent.click(screen.getByRole('button', { name: 'Canceladas' }))
    expect(await screen.findByText('Cancelada')).toBeInTheDocument()
  })

  it('el vacío nombra la pestaña activa', async () => {
    mockedGet.mockResolvedValue(paginated([]))
    renderWithProviders(<AuctionsPage />)
    await screen.findByText('No hay subastas activas en este momento.')
    fireEvent.click(screen.getByRole('button', { name: 'Finalizadas' }))
    await waitFor(() => expect(screen.getByText('No hay subastas finalizadas en este momento.')).toBeInTheDocument())
    fireEvent.click(screen.getByRole('button', { name: 'Canceladas' }))
    await waitFor(() => expect(screen.getByText('No hay subastas canceladas en este momento.')).toBeInTheDocument())
  })
})
