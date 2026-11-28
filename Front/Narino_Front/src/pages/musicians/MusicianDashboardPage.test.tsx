import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { getMyMusicianProfile, uploadMusicianProfileImage } from '@/api/musicians.api'
import MusicianDashboardPage from '@/pages/musicians/MusicianDashboardPage'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'
import type { MusicianProfile, User } from '@/types'

vi.mock('@/api/musicians.api', () => ({
  getMyMusicianProfile: vi.fn(),
  uploadMusicianProfileImage: vi.fn(),
  getMusicianFollowers: vi.fn().mockResolvedValue([]),
  getMyMusicianFollowing: vi.fn().mockResolvedValue([]),
}))
// Los componentes hijos tienen sus propias pruebas; aquí se simulan para ejercitar la página.
vi.mock('@/components/musician/musician-profile-form', () => ({
  MusicianProfileForm: ({ profile }: { profile: MusicianProfile | null }) => <div>formulario:{profile?.slug ?? 'nuevo'}</div>,
}))
vi.mock('@/components/profile/follow-stats-card', () => ({
  FollowStatsCard: (props: { followersCount: number; enabled: boolean; fetchFollowers: () => unknown; fetchFollowing: () => unknown }) => (
    <button onClick={() => { void props.fetchFollowers(); void props.fetchFollowing() }}>
      seguidores:{props.followersCount}:{String(props.enabled)}
    </button>
  ),
}))
vi.mock('@/components/profile/profile-image-upload', () => ({
  ProfileImageUpload: (props: { name: string; currentUrl?: string; disabled?: boolean; onUpload: (f: File) => Promise<unknown> }) => (
    <button disabled={props.disabled} onClick={() => void props.onUpload(new File(['x'], 'f.png')).catch(() => {})}>
      foto:{props.name}:{String(props.currentUrl)}
    </button>
  ),
}))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedProfile = vi.mocked(getMyMusicianProfile)
const mockedUpload = vi.mocked(uploadMusicianProfileImage)

const PROFILE = { slug: 'duo', artistic_name: 'Dúo Andino', profile_image_url: 'https://img.test/d.jpg', followers_count: 9 } as MusicianProfile

describe('MusicianDashboardPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ user: { id: 'u1', first_name: 'Ana' } as User })
    mockedProfile.mockResolvedValue(PROFILE)
  })

  it('muestra el perfil, los accesos y los componentes laterales con los datos del perfil', async () => {
    renderWithProviders(<MusicianDashboardPage />)
    expect(await screen.findByText('formulario:duo')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: '← Cambiar disciplina' })).toHaveAttribute('href', '/dashboard')
    expect(screen.getByRole('link', { name: 'Ver mis obras' })).toHaveAttribute('href', '/dashboard/musician/works')
    expect(screen.getByRole('link', { name: 'Crear evento' })).toHaveAttribute('href', '/dashboard/events/new')
    expect(screen.getByRole('link', { name: 'Añadir obra' })).toHaveAttribute('href', '/dashboard/musician/works/new')
    expect(screen.getByRole('button', { name: 'foto:Dúo Andino:https://img.test/d.jpg' })).toBeEnabled()
    fireEvent.click(screen.getByRole('button', { name: 'seguidores:9:true' }))
  })

  it('mientras carga muestra un esqueleto y sin perfil ofrece el formulario nuevo con la foto deshabilitada', async () => {
    mockedProfile.mockResolvedValue(null)
    const { container } = renderWithProviders(<MusicianDashboardPage />)
    expect(container.querySelector('.animate-pulse, [class*="skeleton"], [class*="h-[560px]"]')).not.toBeNull()
    expect(await screen.findByText('formulario:nuevo')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'foto:Ana:undefined' })).toBeDisabled()
    expect(screen.getByRole('button', { name: 'seguidores:0:false' })).toBeInTheDocument()
  })

  it('sin perfil ni usuario usa un signo de interrogación como nombre', async () => {
    useAuthStore.setState({ user: null })
    mockedProfile.mockResolvedValue(null)
    renderWithProviders(<MusicianDashboardPage />)
    expect(await screen.findByRole('button', { name: 'foto:?:undefined' })).toBeInTheDocument()
  })

  it('sube la foto con el slug del perfil y avisa; si falla muestra el error', async () => {
    mockedUpload.mockResolvedValueOnce(PROFILE)
    renderWithProviders(<MusicianDashboardPage />)
    fireEvent.click(await screen.findByRole('button', { name: /foto:Dúo Andino/ }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Foto de perfil actualizada.'))
    expect(mockedUpload.mock.calls[0][0]).toBe('duo')

    mockedUpload.mockRejectedValueOnce(new Error('Muy pesada'))
    fireEvent.click(screen.getByRole('button', { name: /foto:Dúo Andino/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Muy pesada'))
  })

  it('intentar subir una foto sin perfil guardado avisa que primero se guarda el perfil', async () => {
    mockedProfile.mockResolvedValue(null)
    renderWithProviders(<MusicianDashboardPage />)
    const button = await screen.findByRole('button', { name: 'foto:Ana:undefined' })
    button.removeAttribute('disabled')
    fireEvent.click(button)
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Guarda el perfil antes de subir una foto.'))
    expect(mockedUpload).not.toHaveBeenCalled()
  })
})
