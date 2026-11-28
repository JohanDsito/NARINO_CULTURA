import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { createArtistProfile, updateArtistProfile } from '@/api/artists.api'
import { createMusicianProfile, getMusicGenres, updateMusicianProfile } from '@/api/musicians.api'
import { ArtistProfileForm } from '@/components/artist/artist-profile-form'
import { MusicianProfileForm } from '@/components/musician/musician-profile-form'
import { renderWithProviders } from '@/test/render'
import type { ArtistProfile, MusicianProfile, User } from '@/types'

vi.mock('@/api/artists.api', () => ({ createArtistProfile: vi.fn(), updateArtistProfile: vi.fn() }))
vi.mock('@/api/musicians.api', () => ({
  createMusicianProfile: vi.fn(),
  updateMusicianProfile: vi.fn(),
  getMusicGenres: vi.fn(),
}))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const USER = { id: 'u1', first_name: 'Ana', last_name: 'Paz' } as User

describe('ArtistProfileForm', () => {
  const profile = { slug: 'ana', artistic_name: 'Ana Art', city: 'Pasto', discipline: 'Pintura', bio: 'Bio' } as ArtistProfile

  beforeEach(() => vi.clearAllMocks())

  it('sin perfil propone el nombre del usuario y crea el perfil con valores recortados', async () => {
    vi.mocked(createArtistProfile).mockResolvedValue(profile)
    renderWithProviders(<ArtistProfileForm profile={null} user={USER} />)
    expect(screen.getByText('Crear perfil')).toBeInTheDocument()
    expect(screen.getByLabelText('Nombre artístico')).toHaveValue('Ana Paz')
    fireEvent.change(screen.getByLabelText('Ciudad'), { target: { value: ' Pasto ' } })
    fireEvent.change(screen.getByLabelText('Disciplina'), { target: { value: ' Música ' } })
    fireEvent.change(screen.getByLabelText('Biografía'), { target: { value: ' Hola ' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar perfil' }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Perfil de artista guardado.'))
    expect(createArtistProfile).toHaveBeenCalledWith({ artistic_name: 'Ana Paz', city: 'Pasto', discipline: 'Música', bio: 'Hola' })
  })

  it('sin perfil ni usuario deja el nombre vacío y no deja guardar', async () => {
    renderWithProviders(<ArtistProfileForm profile={null} user={null} />)
    expect(screen.getByLabelText('Nombre artístico')).toHaveValue('')
    fireEvent.click(screen.getByRole('button', { name: 'Guardar perfil' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('El nombre artístico es obligatorio.'))
    expect(createArtistProfile).not.toHaveBeenCalled()
  })

  it('con perfil lo muestra y lo actualiza por su slug; si falla avisa', async () => {
    vi.mocked(updateArtistProfile).mockResolvedValueOnce(profile)
    renderWithProviders(<ArtistProfileForm profile={profile} user={USER} />)
    expect(screen.getByText('Editar perfil')).toBeInTheDocument()
    expect(screen.getByLabelText('Disciplina')).toHaveValue('Pintura')
    fireEvent.change(screen.getByLabelText('Nombre artístico'), { target: { value: 'Nuevo' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar perfil' }))
    await waitFor(() => expect(updateArtistProfile).toHaveBeenCalledWith('ana', expect.objectContaining({ artistic_name: 'Nuevo' })))

    vi.mocked(updateArtistProfile).mockRejectedValueOnce(new Error('Falló'))
    fireEvent.click(screen.getByRole('button', { name: 'Guardar perfil' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Falló'))
  })

  it('un perfil con campos nulos rellena con cadenas vacías', () => {
    renderWithProviders(
      <ArtistProfileForm profile={{ slug: 's', artistic_name: 'X', city: null, discipline: null, bio: null } as unknown as ArtistProfile} user={null} />,
    )
    expect(screen.getByLabelText('Ciudad')).toHaveValue('')
    expect(screen.getByLabelText('Disciplina')).toHaveValue('')
  })

  it('un usuario sin apellido usa solo el nombre', () => {
    renderWithProviders(<ArtistProfileForm profile={null} user={{ first_name: 'Ana' } as User} />)
    expect(screen.getByLabelText('Nombre artístico')).toHaveValue('Ana')
  })
})

describe('MusicianProfileForm', () => {
  const profile = {
    slug: 'duo-andino',
    artistic_name: 'Dúo Andino',
    aggregation_type: 'DUO',
    city: 'Ipiales',
    region: 'Nariño',
    bio: 'Música',
    spotify_url: 'https://open.spotify.com/a',
    youtube_url: 'https://youtube.com/a',
    soundcloud_url: 'https://soundcloud.com/a',
    instagram_handle: '@duo',
    genres: [{ id: 2, name: 'Folclor', slug: 'folclor', description: '', icon: '' }],
  } as unknown as MusicianProfile

  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(getMusicGenres).mockResolvedValue([
      { id: 1, name: 'Rock', slug: 'rock', description: '', icon: '🎸' },
      { id: 2, name: 'Folclor', slug: 'folclor', description: '', icon: '' },
    ])
  })

  it('muestra "Cargando géneros…" y luego los géneros con su icono', async () => {
    renderWithProviders(<MusicianProfileForm profile={null} user={USER} />)
    expect(screen.getByText('Cargando géneros…')).toBeInTheDocument()
    expect(await screen.findByRole('button', { name: /Rock/ })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Folclor' })).toBeInTheDocument()
    expect(screen.getByText('Crear perfil')).toBeInTheDocument()
    expect(screen.getByLabelText('Nombre artístico')).toHaveValue('Ana Paz')
    expect(screen.getByLabelText('Tipo de agrupación')).toHaveValue('SOLISTA')
  })

  it('selecciona y quita géneros con su contador en singular y plural, y crea el perfil', async () => {
    vi.mocked(createMusicianProfile).mockResolvedValue(profile)
    renderWithProviders(<MusicianProfileForm profile={null} user={USER} />)
    fireEvent.click(await screen.findByRole('button', { name: /Rock/ }))
    expect(screen.getByText('1 género seleccionado')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Folclor' }))
    expect(screen.getByText('2 géneros seleccionados')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Folclor' }))
    expect(screen.getByText('1 género seleccionado')).toBeInTheDocument()

    fireEvent.change(screen.getByLabelText('Tipo de agrupación'), { target: { value: 'BANDA' } })
    fireEvent.change(screen.getByLabelText('Ciudad'), { target: { value: ' Pasto ' } })
    fireEvent.change(screen.getByLabelText('Región / Departamento'), { target: { value: 'Nariño' } })
    fireEvent.change(screen.getByLabelText('Biografía'), { target: { value: 'b' } })
    fireEvent.change(screen.getByLabelText('Spotify'), { target: { value: 's' } })
    fireEvent.change(screen.getByLabelText('YouTube'), { target: { value: 'y' } })
    fireEvent.change(screen.getByLabelText('SoundCloud'), { target: { value: 'c' } })
    fireEvent.change(screen.getByLabelText('Instagram'), { target: { value: '@x' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar perfil' }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Perfil de músico guardado.'))
    expect(createMusicianProfile).toHaveBeenCalledWith({
      artistic_name: 'Ana Paz', aggregation_type: 'BANDA', city: 'Pasto', region: 'Nariño', bio: 'b',
      spotify_url: 's', youtube_url: 'y', soundcloud_url: 'c', instagram_handle: '@x', genre_ids: [1],
    })
  })

  it('con perfil carga sus datos y géneros y lo actualiza por slug; si falla avisa', async () => {
    vi.mocked(updateMusicianProfile).mockResolvedValueOnce(profile)
    renderWithProviders(<MusicianProfileForm profile={profile} user={null} />)
    expect(screen.getByText('Editar perfil')).toBeInTheDocument()
    expect(screen.getByLabelText('Ciudad')).toHaveValue('Ipiales')
    expect(screen.getByLabelText('Tipo de agrupación')).toHaveValue('DUO')
    expect(await screen.findByText('1 género seleccionado')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Guardar perfil' }))
    await waitFor(() => expect(updateMusicianProfile).toHaveBeenCalledWith('duo-andino', expect.objectContaining({ genre_ids: [2] })))

    vi.mocked(updateMusicianProfile).mockRejectedValueOnce(new Error('Falló'))
    fireEvent.click(screen.getByRole('button', { name: 'Guardar perfil' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Falló'))
  })

  it('sin nombre artístico avisa y no llama al servicio; sin géneros del servidor no lista ninguno', async () => {
    vi.mocked(getMusicGenres).mockResolvedValue([])
    renderWithProviders(<MusicianProfileForm profile={null} user={null} />)
    fireEvent.click(screen.getByRole('button', { name: 'Guardar perfil' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('El nombre artístico es obligatorio.'))
    expect(createMusicianProfile).not.toHaveBeenCalled()
    await waitFor(() => expect(screen.queryByText('Cargando géneros…')).not.toBeInTheDocument())
  })

  it('usuario sin apellido: usa solo el nombre', () => {
    renderWithProviders(<MusicianProfileForm profile={null} user={{ first_name: 'Ana' } as User} />)
    expect(screen.getByLabelText('Nombre artístico')).toHaveValue('Ana')
  })
})

describe('Formularios de perfil: guardado en curso', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(getMusicGenres).mockResolvedValue([])
  })

  it('el formulario de artista dice "Guardando..." mientras espera', async () => {
    vi.mocked(createArtistProfile).mockReturnValue(new Promise(() => {}))
    renderWithProviders(<ArtistProfileForm profile={null} user={USER} />)
    fireEvent.click(screen.getByRole('button', { name: 'Guardar perfil' }))
    expect(await screen.findByRole('button', { name: 'Guardando...' })).toBeDisabled()
  })

  it('el formulario de músico dice "Guardando..." mientras espera, y el nombre artístico se puede editar', async () => {
    vi.mocked(createMusicianProfile).mockReturnValue(new Promise(() => {}))
    renderWithProviders(<MusicianProfileForm profile={null} user={USER} />)
    fireEvent.change(screen.getByLabelText('Nombre artístico'), { target: { value: ' Trío Nuevo ' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar perfil' }))
    expect(await screen.findByRole('button', { name: 'Guardando...' })).toBeDisabled()
    expect(createMusicianProfile).toHaveBeenCalledWith(expect.objectContaining({ artistic_name: 'Trío Nuevo' }))
  })
})