import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { aiEnhanceArtwork, getArtworkById } from '@/api/artworks.api'
import { addCartItem } from '@/api/marketplace.api'
import ArtworkDetailPage from '@/pages/artworks/ArtworkDetailPage'
import { useAuthStore } from '@/store/authStore'
import { useCartStore } from '@/store/cartStore'
import { makeArtwork } from '@/test/fixtures'
import { renderWithProviders } from '@/test/render'

vi.mock('@/api/artworks.api', () => ({ getArtworkById: vi.fn(), aiEnhanceArtwork: vi.fn() }))
vi.mock('@/api/marketplace.api', () => ({ addCartItem: vi.fn() }))
vi.mock('@/components/artworks/favorite-button', () => ({ FavoriteButton: () => <button>favorito</button> }))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedGet = vi.mocked(getArtworkById)
const mockedAdd = vi.mocked(addCartItem)
const mockedAi = vi.mocked(aiEnhanceArtwork)

function renderPage() {
  return renderWithProviders(<ArtworkDetailPage />, { route: '/artworks/art-1', path: '/artworks/:id' })
}

describe('ArtworkDetailPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ isAuthenticated: false, accessToken: null, refreshToken: null, user: null })
    useCartStore.setState({ items: [] })
    mockedGet.mockResolvedValue(makeArtwork())
  })

  it('muestra el detalle: título, precio, categoría, descripción y datos técnicos', async () => {
    mockedGet.mockResolvedValue(makeArtwork({ views_count: 12 }))
    renderPage()
    expect(await screen.findByRole('heading', { name: 'Volcán Galeras' })).toBeInTheDocument()
    expect(mockedGet).toHaveBeenCalledWith('art-1')
    expect(screen.getByText(/350\.000/)).toBeInTheDocument()
    expect(screen.getByText('Pintura')).toBeInTheDocument()
    expect(screen.getByText('Óleo sobre lienzo')).toBeInTheDocument()
    expect(screen.getByText('Óleo')).toBeInTheDocument()
    expect(screen.getByText('50x70')).toBeInTheDocument()
    expect(screen.getByText('Lienzo')).toBeInTheDocument()
    expect(screen.getByText('12 vistas')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /Catálogo/ })).toHaveAttribute('href', '/artworks')
  })

  it('omite lo que la obra no tiene y prefiere la descripción de IA', async () => {
    mockedGet.mockResolvedValue(
      makeArtwork({ technique: '', dimensions: '', material: '', description: '', ai_description: 'Texto de IA', category_detail: null }),
    )
    renderPage()
    expect(await screen.findByText('Texto de IA')).toBeInTheDocument()
    expect(screen.queryByText('Técnica')).not.toBeInTheDocument()
    expect(screen.queryByText('Dimensiones')).not.toBeInTheDocument()
    expect(screen.queryByText('Material')).not.toBeInTheDocument()
    expect(screen.queryByText(/vistas/)).not.toBeInTheDocument()
  })

  it('sin descripción alguna no pinta el bloque de texto', async () => {
    mockedGet.mockResolvedValue(makeArtwork({ description: '', ai_description: '' }))
    renderPage()
    await screen.findByRole('heading', { name: 'Volcán Galeras' })
    expect(screen.queryByText('Óleo sobre lienzo')).not.toBeInTheDocument()
  })

  it('galería: ordena las imágenes y cambia la principal al elegir una miniatura', async () => {
    mockedGet.mockResolvedValue(
      makeArtwork({
        main_image_url: 'https://img.test/main.jpg',
        images: [
          { id: 'b', image_url: 'https://img.test/b.jpg', order: 2 },
          { id: 'a', image_url: 'https://img.test/a.jpg', order: 1 },
        ],
      }),
    )
    renderPage()
    await screen.findByRole('heading', { name: 'Volcán Galeras' })
    const thumbs = screen.getAllByRole('button').filter((b) => b.querySelector('img[alt=""]'))
    expect(thumbs.map((b) => b.querySelector('img')!.getAttribute('src'))).toEqual([
      'https://img.test/main.jpg',
      'https://img.test/a.jpg',
      'https://img.test/b.jpg',
    ])
    fireEvent.click(thumbs[2])
    expect(screen.getByRole('img', { name: 'Volcán Galeras' })).toHaveAttribute('src', 'https://img.test/b.jpg')
  })

  it('muestra cargando y luego el error cuando la obra no existe', async () => {
    mockedGet.mockRejectedValue(new Error('404'))
    renderPage()
    expect(screen.getByText('Cargando obra…')).toBeInTheDocument()
    expect(await screen.findByText('No se encontró esta obra.')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: '← Volver al catálogo' })).toHaveAttribute('href', '/artworks')
  })

  it('invitado: agrega la obra al carrito local con su imagen principal', async () => {
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Agregar al carrito/ }))
    expect(useCartStore.getState().items).toEqual([
      expect.objectContaining({ artwork_id: 'art-1', title: 'Volcán Galeras', price: 350000, image: 'https://img.test/volcan.jpg', artist_name: 'ana-barniz' }),
    ])
    expect(toast.success).toHaveBeenCalledWith('Obra agregada al carrito')
    expect(mockedAdd).not.toHaveBeenCalled()
    expect(screen.queryByRole('button', { name: /Mejorar descripción con IA/ })).not.toBeInTheDocument()
  })

  it('invitado: sin imagen principal usa la de la galería, o vacío, y sin artista deja el nombre vacío', async () => {
    mockedGet.mockResolvedValue(
      makeArtwork({ main_image_url: '', artist_slug: undefined, images: [{ id: 'a', image_url: 'https://img.test/a.jpg', order: 0 }] }),
    )
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Agregar al carrito/ }))
    expect(useCartStore.getState().items[0]).toMatchObject({ image: 'https://img.test/a.jpg', artist_name: '' })
  })

  it('invitado: sin ninguna imagen guarda la imagen vacía', async () => {
    mockedGet.mockResolvedValue(makeArtwork({ main_image_url: '', images: [] }))
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Agregar al carrito/ }))
    expect(useCartStore.getState().items[0].image).toBe('')
  })

  it('con sesión: agrega al carrito del servidor y avisa', async () => {
    useAuthStore.setState({ isAuthenticated: true })
    mockedAdd.mockResolvedValue({ detail: 'ok' })
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Agregar al carrito/ }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Obra agregada al carrito'))
    expect(mockedAdd).toHaveBeenCalledWith('art-1')
    expect(useCartStore.getState().items).toHaveLength(0)
  })

  it('con sesión: si el servidor falla muestra el mensaje de error', async () => {
    useAuthStore.setState({ isAuthenticated: true })
    mockedAdd.mockRejectedValue(new Error('Sin stock'))
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Agregar al carrito/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith(expect.any(String)))
  })

  it('con sesión: mejora la descripción con IA', async () => {
    useAuthStore.setState({ isAuthenticated: true })
    mockedAi.mockResolvedValue({ ai_tags: {}, ai_description: 'x' })
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Mejorar descripción con IA/ }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Descripción mejorada con IA'))
    expect(mockedAi).toHaveBeenCalledWith('art-1')
  })

  it('con sesión: si la IA no responde avisa que el servicio no está disponible', async () => {
    useAuthStore.setState({ isAuthenticated: true })
    mockedAi.mockRejectedValue(new Error('x'))
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Mejorar descripción con IA/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('El servicio de IA no está disponible.'))
  })

  it('obra en subasta: ofrece ver subastas en lugar de comprar', async () => {
    mockedGet.mockResolvedValue(makeArtwork({ status: 'EN_SUBASTA' }))
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Ver subastas activas/ }))
    expect(screen.getByTestId('location')).toHaveTextContent('/auctions')
    expect(screen.queryByRole('button', { name: /Agregar al carrito/ })).not.toBeInTheDocument()
  })

  it('obra vendida: no ofrece comprar ni subastar', async () => {
    mockedGet.mockResolvedValue(makeArtwork({ status: 'VENDIDA' }))
    renderPage()
    await screen.findByText('Vendida')
    expect(screen.queryByRole('button', { name: /Agregar al carrito/ })).not.toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /Ver subastas activas/ })).not.toBeInTheDocument()
  })
})
