import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { followArtist, getArtistBySlug } from '@/api/artists.api'
import { getArtworks } from '@/api/artworks.api'
import ArtistProfilePage from '@/pages/artist/ArtistProfilePage'
import { useAuthStore } from '@/store/authStore'
import { makeArtwork, paginated } from '@/test/fixtures'
import { renderWithProviders } from '@/test/render'
import type { ArtistProfile } from '@/types'

vi.mock('@/api/artists.api', () => ({ getArtistBySlug: vi.fn(), followArtist: vi.fn() }))
vi.mock('@/api/artworks.api', () => ({ getArtworks: vi.fn() }))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedArtist = vi.mocked(getArtistBySlug)
const mockedFollow = vi.mocked(followArtist)
const mockedArtworks = vi.mocked(getArtworks)

const ARTIST: ArtistProfile = {
  id: 'a1',
  user_id: 'u1',
  slug: 'ana-barniz',
  artistic_name: 'Ana Barniz',
  bio: 'Pintora de Pasto',
  trajectory: '20 años de oficio',
  discipline: 'Pintura',
  city: 'Pasto',
  website_url: 'https://ana.test',
  instagram_url: 'https://instagram.com/ana',
  facebook_url: 'https://facebook.com/ana',
  tiktok_url: 'https://tiktok.com/@ana',
  followers_count: 42,
  is_public: true,
  profile_image_url: 'https://img.test/ana.jpg',
  created_at: '',
  updated_at: '',
  is_following: false,
}

function renderPage() {
  return renderWithProviders(<ArtistProfilePage />, { route: '/artists/ana-barniz', path: '/artists/:slug' })
}

describe('ArtistProfilePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ isAuthenticated: false })
    mockedArtist.mockResolvedValue(ARTIST)
    mockedArtworks.mockResolvedValue(paginated([makeArtwork()], { count: 5 }))
  })

  it('muestra el perfil completo con redes, estadísticas y portafolio', async () => {
    renderPage()
    expect(screen.getByText('Cargando perfil…')).toBeInTheDocument()
    expect(await screen.findByRole('heading', { name: 'Ana Barniz' })).toBeInTheDocument()
    expect(mockedArtist).toHaveBeenCalledWith('ana-barniz')
    expect(mockedArtworks).toHaveBeenCalledWith({ artist: 'ana-barniz', page_size: 9 })
    expect(screen.getByText('Perfil público')).toBeInTheDocument()
    expect(screen.getByText('Pintura')).toBeInTheDocument()
    expect(screen.getByText('📍 Pasto')).toBeInTheDocument()
    expect(screen.getByText('Pintora de Pasto')).toBeInTheDocument()
    expect(screen.getByText('20 años de oficio')).toBeInTheDocument()
    expect(screen.getByAltText('Ana Barniz')).toHaveAttribute('src', 'https://img.test/ana.jpg')
    expect(screen.getByRole('link', { name: /Instagram/ })).toHaveAttribute('href', 'https://instagram.com/ana')
    expect(screen.getByRole('link', { name: /Facebook/ })).toHaveAttribute('href', 'https://facebook.com/ana')
    expect(screen.getByRole('link', { name: /TikTok/ })).toHaveAttribute('href', 'https://tiktok.com/@ana')
    expect(screen.getByRole('link', { name: /Sitio web/ })).toHaveAttribute('href', 'https://ana.test')
    expect(screen.getByText('42')).toBeInTheDocument()
    expect(screen.getByText('5')).toBeInTheDocument()
    expect(await screen.findByRole('link', { name: /Volcán Galeras/ })).toHaveAttribute('href', '/artworks/art-1')
    expect(screen.getByText('Disponible')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /Seguir artista/ })).not.toBeInTheDocument()
  })

  it('perfil mínimo: inicial como avatar, sin redes, sin textos opcionales y portafolio vacío', async () => {
    mockedArtist.mockResolvedValue({
      ...ARTIST, profile_image_url: undefined, discipline: null, city: '', bio: '', trajectory: '', is_public: false,
      website_url: '', instagram_url: '', facebook_url: '', tiktok_url: '',
    })
    mockedArtworks.mockResolvedValue(paginated([], { count: 0 }))
    renderPage()
    expect(await screen.findByText('A')).toBeInTheDocument()
    expect(screen.queryByText('Perfil público')).not.toBeInTheDocument()
    expect(screen.queryByText(/📍/)).not.toBeInTheDocument()
    expect(screen.queryByRole('link', { name: /Instagram/ })).not.toBeInTheDocument()
    expect(await screen.findByText('Aún no hay obras publicadas')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: '← Explorar más artistas' })).toHaveAttribute('href', '/artists')
    expect(screen.queryByText('Obras')).not.toBeInTheDocument()
  })

  it('etiquetas y variantes de estado de las obras y elección de imagen', async () => {
    mockedArtworks.mockResolvedValue(
      paginated([
        makeArtwork({ id: '1', title: 'En remate', status: 'EN_SUBASTA' }),
        makeArtwork({ id: '2', title: 'Vendida', status: 'VENDIDA', main_image_url: '' , images: [{ id: 'x', image_url: 'https://img.test/o0.jpg', order: 0 }] }),
        makeArtwork({ id: '3', title: 'Inactiva', status: 'INACTIVA', main_image_url: '', images: [{ id: 'y', image_url: 'https://img.test/o2.jpg', order: 2 }] }),
        makeArtwork({ id: '4', title: 'Sin imagen', main_image_url: '', images: [] }),
      ]),
    )
    renderPage()
    expect(await screen.findByText('En subasta')).toBeInTheDocument()
    expect(screen.getAllByText('Vendida').length).toBeGreaterThan(0)
    expect(screen.getByText('Inactiva', { selector: 'span' })).toBeInTheDocument()
    expect(screen.getByAltText('Vendida')).toHaveAttribute('src', 'https://img.test/o0.jpg')
    expect(screen.getByAltText('Inactiva')).toHaveAttribute('src', 'https://img.test/o2.jpg')
  })

  it('no encontrado: muestra el error y vuelve al directorio', async () => {
    mockedArtist.mockRejectedValue(new Error('404'))
    renderPage()
    expect(await screen.findByText('No se encontró este perfil de artista.')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: '← Volver al directorio' })).toHaveAttribute('href', '/artists')
  })

  it('con sesión: sigue y deja de seguir al artista con cambio inmediato del botón', async () => {
    useAuthStore.setState({ isAuthenticated: true })
    mockedFollow.mockResolvedValue({ detail: 'Ahora sigues a Ana' })
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Seguir artista/ }))
    expect(await screen.findByRole('button', { name: /Siguiendo/ })).toBeInTheDocument()
    expect(toast.success).toHaveBeenCalledWith('Ahora sigues a Ana')
    expect(mockedFollow).toHaveBeenCalledWith('ana-barniz')
    mockedFollow.mockResolvedValue({ detail: 'Dejaste de seguir' })
    fireEvent.click(screen.getByRole('button', { name: /Siguiendo/ }))
    expect(await screen.findByRole('button', { name: /Seguir artista/ })).toBeInTheDocument()
  })

  it('si el artista ya es seguido arranca como "Siguiendo"; si falla el cambio avisa', async () => {
    useAuthStore.setState({ isAuthenticated: true })
    mockedArtist.mockResolvedValue({ ...ARTIST, is_following: true })
    mockedFollow.mockRejectedValue(new Error('x'))
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Siguiendo/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No se pudo actualizar el seguimiento.'))
    expect(screen.getByRole('button', { name: /Siguiendo/ })).toBeInTheDocument()
  })

  it('sin is_following definido se asume que no lo sigue', async () => {
    useAuthStore.setState({ isAuthenticated: true })
    mockedArtist.mockResolvedValue({ ...ARTIST, is_following: undefined })
    renderPage()
    expect(await screen.findByRole('button', { name: /Seguir artista/ })).toBeInTheDocument()
  })
})
