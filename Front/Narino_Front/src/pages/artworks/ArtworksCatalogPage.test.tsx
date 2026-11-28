import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'

import { getArtworkCategories, getArtworks } from '@/api/artworks.api'
import ArtworksCatalogPage from '@/pages/artworks/ArtworksCatalogPage'
import { makeArtwork, paginated } from '@/test/fixtures'
import { renderWithProviders } from '@/test/render'

vi.mock('@/api/artworks.api', () => ({ getArtworks: vi.fn(), getArtworkCategories: vi.fn() }))

const mockedArtworks = vi.mocked(getArtworks)
const mockedCategories = vi.mocked(getArtworkCategories)

describe('ArtworksCatalogPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockedCategories.mockResolvedValue([{ id: 1, name: 'Pintura', slug: 'pintura' }])
  })

  it('lista obras con precio, categoría, etiqueta de estado y singular/plural del contador', async () => {
    mockedArtworks.mockResolvedValue(
      paginated([
        makeArtwork({ id: 'a1', title: 'Disponible' }),
        makeArtwork({ id: 'a2', title: 'En remate', status: 'EN_SUBASTA', category_detail: null }),
        makeArtwork({ id: 'a3', title: 'Ya vendida', status: 'VENDIDA', main_image_url: '', images: [{ id: 'i', image_url: 'https://img.test/x.jpg', order: 0 }] }),
        makeArtwork({ id: 'a4', title: 'Sin foto', main_image_url: '', images: [] }),
      ]),
    )
    renderWithProviders(<ArtworksCatalogPage />)
    expect(await screen.findByRole('link', { name: /Disponible/ })).toHaveAttribute('href', '/artworks/a1')
    expect(screen.getByText('4 obras encontradas')).toBeInTheDocument()
    expect(screen.getByText('En subasta')).toBeInTheDocument()
    expect(screen.getByText('Vendida')).toBeInTheDocument()
    expect(screen.getByRole('img', { name: 'Ya vendida' })).toHaveAttribute('src', 'https://img.test/x.jpg')
    expect(screen.getByRole('option', { name: 'Pintura' })).toBeInTheDocument()
  })

  it('usa el singular con una sola obra', async () => {
    mockedArtworks.mockResolvedValue(paginated([makeArtwork()]))
    renderWithProviders(<ArtworksCatalogPage />)
    expect(await screen.findByText('1 obra encontrada')).toBeInTheDocument()
  })

  it('muestra esqueletos al cargar y el vacío cuando no hay resultados', async () => {
    mockedArtworks.mockResolvedValue(paginated([], { count: 0 }))
    const { container } = renderWithProviders(<ArtworksCatalogPage />)
    expect(container.querySelectorAll('.animate-pulse')).toHaveLength(8)
    expect(await screen.findByText('No se encontraron obras con esos filtros.')).toBeInTheDocument()
    expect(screen.getByText('0 obras encontradas')).toBeInTheDocument()
    expect(screen.queryByText('← Anterior')).not.toBeInTheDocument()
  })

  it('filtra por búsqueda y categoría, y vuelve a la página 1', async () => {
    mockedArtworks.mockResolvedValue(paginated([makeArtwork()]))
    renderWithProviders(<ArtworksCatalogPage />)
    await screen.findByText('1 obra encontrada')

    fireEvent.change(screen.getByPlaceholderText('Buscar obras…'), { target: { value: 'volcán' } })
    await waitFor(() =>
      expect(mockedArtworks).toHaveBeenLastCalledWith({ search: 'volcán', category: undefined, page: 1, page_size: 12 }),
    )
    await screen.findByRole('option', { name: 'Pintura' })
    fireEvent.change(screen.getByRole('combobox'), { target: { value: '1' } })
    await waitFor(() =>
      expect(mockedArtworks).toHaveBeenLastCalledWith({ search: 'volcán', category: '1', page: 1, page_size: 12 }),
    )
  })

  it('pagina hacia adelante y atrás respetando next y previous', async () => {
    mockedArtworks.mockResolvedValueOnce(paginated([makeArtwork({ title: 'Página uno' })], { next: 'n', count: 24 }))
    renderWithProviders(<ArtworksCatalogPage />)
    await screen.findByText('Página uno')
    expect(screen.getByRole('button', { name: '← Anterior' })).toBeDisabled()

    mockedArtworks.mockResolvedValueOnce(paginated([makeArtwork({ title: 'Página dos' })], { previous: 'p', count: 24 }))
    fireEvent.click(screen.getByRole('button', { name: 'Siguiente →' }))
    await screen.findByText('Página dos')
    expect(screen.getByText('Página 2')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Siguiente →' })).toBeDisabled()

    mockedArtworks.mockResolvedValueOnce(paginated([makeArtwork({ title: 'Página uno' })], { next: 'n', count: 24 }))
    fireEvent.click(screen.getByRole('button', { name: '← Anterior' }))
    await waitFor(() => expect(screen.getByText('Página 1')).toBeInTheDocument())
  })
})
