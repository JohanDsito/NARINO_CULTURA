import { describe, it, expect, vi, beforeEach } from 'vitest'
import { screen, waitFor } from '@testing-library/react'

import { getArtworks } from '@/api/artworks.api'
import { getAuctions } from '@/api/auctions.api'
import MarketplacePage from '@/pages/marketplace/MarketplacePage'
import { makeArtwork, paginated } from '@/test/fixtures'
import { renderWithProviders } from '@/test/render'
import type { Auction } from '@/types'

vi.mock('@/api/artworks.api', () => ({ getArtworks: vi.fn() }))
vi.mock('@/api/auctions.api', () => ({ getAuctions: vi.fn() }))

const mockedArtworks = vi.mocked(getArtworks)
const mockedAuctions = vi.mocked(getAuctions)

function makeAuction(id: string, price: string): Auction {
  return {
    id,
    artwork: 'a',
    seller: 's',
    base_price: '1000',
    current_price: price,
    highest_bidder: null,
    status: 'ACTIVA',
    starts_at: '',
    ends_at: '',
    winner: null,
    created_at: '',
    updated_at: '',
  }
}

describe('MarketplacePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('muestra obras destacadas con precio y categoría, y subastas paginadas', async () => {
    mockedArtworks.mockResolvedValue(
      paginated(
        [
          makeArtwork({ id: 'a1', title: 'Con principal' }),
          makeArtwork({ id: 'a2', title: 'Con galería', main_image_url: '', images: [{ id: 'i', image_url: 'https://img.test/g.jpg', order: 0 }], category_detail: null }),
          makeArtwork({ id: 'a3', title: 'Sin imagen', main_image_url: '', images: [] }),
        ],
        { count: 25 },
      ),
    )
    mockedAuctions.mockResolvedValue(paginated([makeAuction('s1', '500000'), makeAuction('s2', '90000')]))
    renderWithProviders(<MarketplacePage />)

    expect(await screen.findByRole('link', { name: /Con principal/ })).toHaveAttribute('href', '/artworks/a1')
    expect(screen.getByText('25')).toBeInTheDocument()
    expect(screen.getAllByText('Pintura')).toHaveLength(2)
    expect(screen.getByRole('img', { name: 'Con galería' })).toHaveAttribute('src', 'https://img.test/g.jpg')
    expect(screen.getByRole('img', { name: 'Sin imagen' })).toBeInTheDocument()
    expect(await screen.findByText('Subastas en Curso')).toBeInTheDocument()
    expect(screen.getAllByText('En curso')).toHaveLength(2)
    expect(screen.getByText(/500\.000/)).toBeInTheDocument()
    expect(mockedArtworks).toHaveBeenCalledWith({ status: 'DISPONIBLE', page_size: 6 })
    expect(mockedAuctions).toHaveBeenCalledWith({ status: 'ACTIVA', page_size: 3 })
  })

  it('acepta subastas como arreglo plano', async () => {
    mockedArtworks.mockResolvedValue(paginated([]))
    mockedAuctions.mockResolvedValue([makeAuction('s1', '777000')])
    renderWithProviders(<MarketplacePage />)
    expect(await screen.findByText(/777\.000/)).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /En curso/ })).toHaveAttribute('href', '/auctions/s1')
  })

  it('sin datos no muestra secciones y los contadores quedan en su valor por defecto', async () => {
    mockedArtworks.mockResolvedValue(paginated([], { count: 0 }))
    mockedAuctions.mockResolvedValue(paginated([]))
    renderWithProviders(<MarketplacePage />)
    await waitFor(() => expect(screen.getAllByText('0')).toHaveLength(2))
    expect(screen.queryByText('Obras Disponibles')).not.toBeInTheDocument()
    expect(screen.queryByText('Subastas en Curso')).not.toBeInTheDocument()
    expect(screen.getByRole('link', { name: /Ver catálogo completo/ })).toHaveAttribute('href', '/artworks')
    expect(screen.getByRole('link', { name: /Subastas activas/ })).toHaveAttribute('href', '/auctions')
  })

  it('mientras carga el total de obras se muestra un signo más', () => {
    mockedArtworks.mockReturnValue(new Promise(() => {}))
    mockedAuctions.mockReturnValue(new Promise(() => {}))
    renderWithProviders(<MarketplacePage />)
    expect(screen.getByText('+')).toBeInTheDocument()
  })
})
