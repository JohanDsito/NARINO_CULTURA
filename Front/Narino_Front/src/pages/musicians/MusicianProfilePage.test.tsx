import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { followMusician, getMusicianBySlug, getMusicianWorks } from '@/api/musicians.api'
import MusicianProfilePage from '@/pages/musicians/MusicianProfilePage'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'
import type { MusicalWork, MusicianProfile } from '@/types'

vi.mock('@/api/musicians.api', () => ({
  getMusicianBySlug: vi.fn(),
  getMusicianWorks: vi.fn(),
  followMusician: vi.fn(),
}))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedMusician = vi.mocked(getMusicianBySlug)
const mockedWorks = vi.mocked(getMusicianWorks)
const mockedFollow = vi.mocked(followMusician)

const MUSICIAN = {
  id: 'm1',
  slug: 'duo-andino',
  artistic_name: 'Dúo Andino',
  aggregation_type: 'DUO',
  city: 'Ipiales',
  region: 'Nariño',
  founding_year: 2010,
  bio: 'Música de los Andes',
  genres: [{ id: 1, name: 'Folclor', slug: 'f', description: '', icon: '🪕' }],
  spotify_url: 'https://open.spotify.com/a',
  youtube_url: 'https://youtube.com/a',
  soundcloud_url: 'https://soundcloud.com/a',
  instagram_handle: '@duoandino',
  website_url: 'https://duo.test',
  profile_image_url: 'https://img.test/d.jpg',
  is_verified: true,
  followers_count: 33,
} as MusicianProfile

function work(overrides: Partial<MusicalWork>): MusicalWork {
  return {
    id: 'w', title: 'Obra', work_type: 'STUDIO', youtube_url: '', soundcloud_embed: '', spotify_track_url: '',
    thumbnail: '', description: '', views_count: 0, is_featured: false, ...overrides,
  } as MusicalWork
}

function renderPage() {
  return renderWithProviders(<MusicianProfilePage />, { route: '/musicians/duo-andino', path: '/musicians/:slug' })
}

describe('MusicianProfilePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ isAuthenticated: false })
    mockedMusician.mockResolvedValue(MUSICIAN)
    mockedWorks.mockResolvedValue([])
  })

  it('muestra el perfil completo con redes y sin obras', async () => {
    renderPage()
    expect(screen.getByText('Cargando perfil del músico…')).toBeInTheDocument()
    expect(await screen.findByRole('heading', { name: 'Dúo Andino' })).toBeInTheDocument()
    expect(mockedMusician).toHaveBeenCalledWith('duo-andino')
    expect(mockedWorks).toHaveBeenCalledWith('duo-andino')
    expect(screen.getAllByText('Dúo')[0]).toBeInTheDocument()
    expect(screen.getByText('Verificado')).toBeInTheDocument()
    expect(screen.getByText(/Ipiales, Nariño · Desde 2010/)).toBeInTheDocument()
    expect(screen.getByText(/Folclor/)).toBeInTheDocument()
    expect(screen.getByText('Música de los Andes')).toBeInTheDocument()
    expect(screen.getByAltText('Dúo Andino')).toHaveAttribute('src', 'https://img.test/d.jpg')
    expect(screen.getByRole('link', { name: /Spotify/ })).toHaveAttribute('href', 'https://open.spotify.com/a')
    expect(screen.getByRole('link', { name: /YouTube/ })).toHaveAttribute('href', 'https://youtube.com/a')
    expect(screen.getByRole('link', { name: /SoundCloud/ })).toHaveAttribute('href', 'https://soundcloud.com/a')
    expect(screen.getByRole('link', { name: /@duoandino/ })).toHaveAttribute('href', 'https://instagram.com/duoandino')
    expect(screen.getByRole('link', { name: /Sitio web/ })).toHaveAttribute('href', 'https://duo.test')
    expect(screen.getByText('33')).toBeInTheDocument()
    expect(await screen.findByText('Aún no hay obras publicadas')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /Seguir/ })).not.toBeInTheDocument()
  })

  it('perfil mínimo: inicial, tipo desconocido, sin año, géneros, bio ni redes', async () => {
    mockedMusician.mockResolvedValue({
      ...MUSICIAN, profile_image_url: '', is_verified: false, founding_year: undefined, genres: [], bio: '',
      spotify_url: '', youtube_url: '', soundcloud_url: '', instagram_handle: '', website_url: '',
      aggregation_type: 'OTRO' as MusicianProfile['aggregation_type'],
    })
    renderPage()
    expect(await screen.findByText('D', { selector: 'span' })).toBeInTheDocument()
    expect(screen.getByText('OTRO')).toBeInTheDocument()
    expect(screen.queryByText('Verificado')).not.toBeInTheDocument()
    expect(screen.queryByText(/Desde/)).not.toBeInTheDocument()
    expect(screen.queryByRole('link', { name: /Spotify/ })).not.toBeInTheDocument()
  })

  it('obras: videos con embed o enlace, y música con enlaces, duración, año y destacada', async () => {
    mockedWorks.mockResolvedValue([
      work({ id: 'v1', title: 'Video embed', work_type: 'VIDEO', youtube_url: 'https://youtu.be/abc123' }),
      work({ id: 'v2', title: 'Video sin id', work_type: 'VIDEO', youtube_url: 'https://example.com/video' }),
      work({
        id: 'a1', title: 'Pista completa', work_type: 'STUDIO', thumbnail: 'https://img.test/t.jpg', is_featured: true,
        release_date: '2024-05-05', duration_seconds: 185, description: 'Descripción de la pista',
        spotify_track_url: 'https://open.spotify.com/t', soundcloud_embed: 'https://soundcloud.com/t', youtube_url: 'https://youtube.com/t',
      }),
      work({ id: 'a2', title: 'Pista simple', work_type: 'PODCAST', soundcloud_embed: '<iframe></iframe>', duration_seconds: 0 }),
      work({ id: 'a3', title: 'Pista rara', work_type: 'RARA' as MusicalWork['work_type'] }),
    ])
    renderPage()
    expect(await screen.findByTitle('Video embed')).toHaveAttribute('src', 'https://www.youtube-nocookie.com/embed/abc123')
    expect(screen.getByRole('link', { name: /Video sin id/ })).toHaveAttribute('href', 'https://example.com/video')
    expect(screen.getByText('Videos')).toBeInTheDocument()
    expect(screen.getByText('Música')).toBeInTheDocument()
    expect(screen.getByText(/Estudio · 2024 · 3:05/)).toBeInTheDocument()
    expect(screen.getByAltText('Pista completa')).toHaveAttribute('src', 'https://img.test/t.jpg')
    expect(screen.getByText('Destacada')).toBeInTheDocument()
    expect(screen.getByText('Descripción de la pista')).toBeInTheDocument()
    const links = screen.getAllByRole('link').map((a) => a.getAttribute('href'))
    expect(links).toEqual(expect.arrayContaining(['https://open.spotify.com/t', 'https://soundcloud.com/t', 'https://youtube.com/t']))
    expect(screen.getByText('Podcast')).toBeInTheDocument()
    expect(screen.getByText('RARA')).toBeInTheDocument()
    expect(screen.getByText('5', { selector: 'p.text-azul' })).toBeInTheDocument()
  })

  it('solo obras de audio: no hay sección de videos; solo videos sin enlace de YouTube cuentan como obra pero no se listan', async () => {
    mockedWorks.mockResolvedValue([work({ id: 'v0', title: 'Video vacío', work_type: 'VIDEO', youtube_url: '' })])
    renderPage()
    await screen.findByRole('heading', { name: 'Dúo Andino' })
    await waitFor(() => expect(screen.queryByText('Aún no hay obras publicadas')).not.toBeInTheDocument())
    expect(screen.queryByText('Videos')).not.toBeInTheDocument()
    expect(screen.queryByText('Música')).not.toBeInTheDocument()
  })

  it('no encontrado: error y enlace al directorio', async () => {
    mockedMusician.mockRejectedValue(new Error('404'))
    renderPage()
    expect(await screen.findByText('No se encontró este perfil.')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: '← Volver a músicos' })).toHaveAttribute('href', '/musicians')
  })

  it('con sesión: sigue y deja de seguir; si falla avisa', async () => {
    useAuthStore.setState({ isAuthenticated: true })
    mockedFollow.mockResolvedValueOnce({ detail: 'Ahora sigues al músico' })
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: /Seguir/ }))
    expect(await screen.findByRole('button', { name: /Siguiendo/ })).toBeInTheDocument()
    expect(toast.success).toHaveBeenCalledWith('Ahora sigues al músico')
    expect(mockedFollow).toHaveBeenCalledWith('duo-andino')

    mockedFollow.mockRejectedValueOnce(new Error('x'))
    fireEvent.click(screen.getByRole('button', { name: /Siguiendo/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('No se pudo actualizar el seguimiento.'))
  })
})
