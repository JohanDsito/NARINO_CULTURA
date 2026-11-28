import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { getMyArtistProfile, uploadArtistProfileImage } from '@/api/artists.api'
import ArtistDashboardPage from '@/pages/artist/ArtistDashboardPage'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'
import type { ArtistProfile, User } from '@/types'

vi.mock('@/api/artists.api', () => ({
  getMyArtistProfile: vi.fn(),
  uploadArtistProfileImage: vi.fn(),
  getArtistFollowers: vi.fn().mockResolvedValue([]),
  getMyFollowing: vi.fn().mockResolvedValue([]),
}))
vi.mock('@/components/artist/artist-profile-form', () => ({ ArtistProfileForm: () => <div>formulario-artista</div> }))
vi.mock('@/components/profile/follow-stats-card', () => ({
  FollowStatsCard: (props: { followersCount: number; fetchFollowers: () => unknown; fetchFollowing: () => unknown }) => (
    <button onClick={() => { void props.fetchFollowers(); void props.fetchFollowing() }}>seguidores:{props.followersCount}</button>
  ),
}))
vi.mock('@/components/profile/profile-image-upload', () => ({
  ProfileImageUpload: (props: { name: string; disabled?: boolean; onUpload: (f: File) => Promise<unknown> }) => (
    <button disabled={props.disabled} onClick={() => void props.onUpload(new File(['x'], 'f.png')).catch(() => {})}>foto:{props.name}</button>
  ),
}))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedProfile = vi.mocked(getMyArtistProfile)
const mockedUpload = vi.mocked(uploadArtistProfileImage)

const PROFILE = { slug: 'ana', artistic_name: 'Ana Art', followers_count: 4 } as ArtistProfile

describe('ArtistDashboardPage: foto y comunidad', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ user: { id: 'u1', role: 'artist', first_name: 'Ana' } as User })
    mockedProfile.mockResolvedValue(PROFILE)
  })

  it('sube la foto con el slug del perfil y avisa; si falla muestra el error', async () => {
    mockedUpload.mockResolvedValueOnce(PROFILE)
    renderWithProviders(<ArtistDashboardPage />)
    fireEvent.click(await screen.findByRole('button', { name: 'foto:Ana Art' }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Foto de perfil actualizada.'))
    expect(mockedUpload.mock.calls[0][0]).toBe('ana')

    mockedUpload.mockRejectedValueOnce(new Error('Muy pesada'))
    fireEvent.click(screen.getByRole('button', { name: 'foto:Ana Art' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Muy pesada'))
  })

  it('pide los seguidores del perfil y a quién sigue la usuaria', async () => {
    const { getArtistFollowers, getMyFollowing } = await import('@/api/artists.api')
    renderWithProviders(<ArtistDashboardPage />)
    fireEvent.click(await screen.findByRole('button', { name: 'seguidores:4' }))
    expect(getArtistFollowers).toHaveBeenCalledWith('ana')
    expect(getMyFollowing).toHaveBeenCalled()
  })

  it('sin perfil guardado no deja subir foto y sin usuario usa "?" como nombre', async () => {
    useAuthStore.setState({ user: null })
    mockedProfile.mockResolvedValue(null)
    renderWithProviders(<ArtistDashboardPage />)
    expect(await screen.findByRole('button', { name: 'foto:?' })).toBeDisabled()
    expect(mockedProfile).not.toHaveBeenCalled()
  })

  it('intentar subir sin perfil avisa que primero se guarda el perfil', async () => {
    // El botón de la foto está deshabilitado sin perfil, pero la mutación igual se protege por si se invoca
    mockedProfile.mockResolvedValue(null)
    renderWithProviders(<ArtistDashboardPage />)
    const button = await screen.findByRole('button', { name: 'foto:Ana' })
    button.removeAttribute('disabled')
    fireEvent.click(button)
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Guarda el perfil antes de subir una foto.'))
    expect(mockedUpload).not.toHaveBeenCalled()
  })
})
