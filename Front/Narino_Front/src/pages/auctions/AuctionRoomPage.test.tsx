import { describe, it, expect, vi, beforeEach } from 'vitest'
import { act, fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { getAuctionById, placeBid } from '@/api/auctions.api'
import AuctionRoomPage from '@/pages/auctions/AuctionRoomPage'
import { useAuctionSocket, type AuctionSocketCallback } from '@/services/auctionSocket'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'
import type { Auction, AuctionStatus } from '@/types'

vi.mock('@/api/auctions.api', () => ({ getAuctionById: vi.fn(), placeBid: vi.fn() }))
vi.mock('@/services/auctionSocket', () => ({ useAuctionSocket: vi.fn() }))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn(), info: vi.fn() } }))

const mockedGet = vi.mocked(getAuctionById)
const mockedBid = vi.mocked(placeBid)
const mockedSocket = vi.mocked(useAuctionSocket)

function makeAuction(status: AuctionStatus = 'ACTIVA'): Auction {
  return {
    id: '9',
    artwork: 'a',
    seller: 's',
    base_price: '100000',
    current_price: '200000',
    highest_bidder: null,
    status,
    starts_at: '2026-01-01T10:00:00Z',
    ends_at: new Date(Date.now() + 2 * 24 * 3600 * 1000).toISOString(),
    winner: null,
    created_at: '',
    updated_at: '',
  }
}

let emit: AuctionSocketCallback

function renderRoom() {
  return renderWithProviders(<AuctionRoomPage />, { route: '/auctions/9', path: '/auctions/:id' })
}

describe('AuctionRoomPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ isAuthenticated: true })
    mockedGet.mockResolvedValue(makeAuction())
    mockedSocket.mockImplementation((_id, cb) => {
      emit = cb
      return { current: null }
    })
  })

  it('muestra cargando, y luego la puja actual, el precio base, el tiempo restante y los detalles', async () => {
    renderRoom()
    expect(screen.getByText('Entrando a la sala de subasta…')).toBeInTheDocument()
    expect(await screen.findByText(/200\.000/)).toBeInTheDocument()
    expect(screen.getByText(/Precio base:/)).toHaveTextContent('100.000')
    expect(screen.getByText('En curso')).toBeInTheDocument()
    expect(screen.getByText('Tiempo restante')).toBeInTheDocument()
    expect(screen.getByText('Mínimo: $ 200.001')).toBeInTheDocument()
    expect(mockedGet).toHaveBeenCalledWith('9')
    expect(mockedSocket).toHaveBeenLastCalledWith('9', expect.any(Function), true)
  })

  it('subasta inexistente: muestra el error y vuelve a subastas', async () => {
    mockedGet.mockRejectedValue(new Error('404'))
    renderRoom()
    expect(await screen.findByText('No se encontró esta subasta.')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: '← Volver a subastas' })).toHaveAttribute('href', '/auctions')
  })

  it('subasta cerrada: sin formulario ni tiempo restante, y no abre el socket', async () => {
    mockedGet.mockResolvedValue(makeAuction('CERRADA'))
    renderRoom()
    expect(await screen.findByText('Finalizada')).toBeInTheDocument()
    expect(screen.queryByText('Hacer una puja')).not.toBeInTheDocument()
    expect(screen.queryByText('Tiempo restante')).not.toBeInTheDocument()
    expect(mockedSocket).toHaveBeenLastCalledWith('9', expect.any(Function), false)
  })

  it('subasta cancelada se etiqueta como cancelada', async () => {
    mockedGet.mockResolvedValue(makeAuction('CANCELADA'))
    renderRoom()
    expect(await screen.findByText('Cancelada')).toBeInTheDocument()
  })

  it('sin sesión pide iniciar sesión para pujar', async () => {
    useAuthStore.setState({ isAuthenticated: false })
    renderRoom()
    expect(await screen.findByText('Debes iniciar sesión para hacer una puja.')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Iniciar sesión' })).toHaveAttribute('href', '/login')
    expect(screen.queryByText('Hacer una puja')).not.toBeInTheDocument()
  })

  it('el botón Pujar se habilita solo con un monto mayor al actual y registra la puja', async () => {
    mockedBid.mockResolvedValue({ detail: 'ok', bid_id: 'b' })
    renderRoom()
    const input = await screen.findByRole('spinbutton')
    const button = screen.getByRole('button', { name: /Pujar/ })
    expect(button).toBeDisabled()
    fireEvent.change(input, { target: { value: '150000' } })
    expect(button).toBeDisabled()
    fireEvent.change(input, { target: { value: '250000' } })
    expect(button).toBeEnabled()
    fireEvent.click(button)
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Puja registrada exitosamente'))
    expect(mockedBid).toHaveBeenCalledWith('9', 250000)
    expect(input).toHaveValue(null)
  })

  it('si la puja falla avisa y conserva el monto', async () => {
    mockedBid.mockRejectedValue(new Error('x'))
    renderRoom()
    const input = await screen.findByRole('spinbutton')
    fireEvent.change(input, { target: { value: '300000' } })
    fireEvent.click(screen.getByRole('button', { name: /Pujar/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No se pudo registrar la puja. Verifica el monto.'))
    expect(input).toHaveValue(300000)
  })

  it('eventos en tiempo real: conectado, snapshot, puja nueva (historial limitado a 20) y cierre', async () => {
    renderRoom()
    await screen.findByText(/200\.000/)
    expect(screen.queryByText('En tiempo real')).not.toBeInTheDocument()

    act(() => emit({ type: 'connected', auction_id: '9' }))
    expect(screen.getByText('En tiempo real')).toBeInTheDocument()

    act(() => emit({ type: 'snapshot', current_price: '220000', highest_bidder_id: null, status: 'ACTIVA', ends_at: '' }))
    expect(screen.getByText(/220\.000/, { selector: 'p.font-display' })).toBeInTheDocument()

    for (let i = 1; i <= 21; i++) {
      act(() =>
        emit({ type: 'bid_placed', current_price: String(220000 + i * 1000), highest_bidder_id: 'u', amount: String(220000 + i * 1000), bidder_name: 'Ana' }),
      )
    }
    expect(screen.getByText('Pujas recientes')).toBeInTheDocument()
    expect(toast.success).toHaveBeenCalledWith(expect.stringContaining('Nueva puja'))
    expect(screen.getByText('Mínimo: $ 241.001')).toBeInTheDocument()
    expect(document.querySelectorAll('.border-b.border-border.last\\:border-0')).toHaveLength(20)

    act(() => emit({ type: 'auction_closed', winner_id: null }))
    expect(toast.info).toHaveBeenCalledWith('La subasta ha finalizado.')

    act(() => emit({ type: 'error', message: 'x' }))
  })
})
