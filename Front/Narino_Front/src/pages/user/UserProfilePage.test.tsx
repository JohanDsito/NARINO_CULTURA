import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { updateMe, uploadAvatar } from '@/api/auth.api'
import UserProfilePage from '@/pages/user/UserProfilePage'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'
import type { User } from '@/types'

vi.mock('@/api/auth.api', () => ({ updateMe: vi.fn(), uploadAvatar: vi.fn(), deleteAccount: vi.fn() }))
// El componente real se prueba aparte; aquí se simula para ejercitar solo los manejadores de la página
vi.mock('@/components/profile/profile-image-upload', () => ({
  ProfileImageUpload: ({ onUpload, name, currentUrl }: { onUpload: (f: File) => Promise<unknown>; name: string; currentUrl?: string }) => (
    <button onClick={() => void onUpload(new File(['x'], 'foto.png')).catch(() => {})}>
      subir-foto:{name}:{String(currentUrl)}
    </button>
  ),
}))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedUpdate = vi.mocked(updateMe)
const mockedAvatar = vi.mocked(uploadAvatar)

const USER = {
  id: 'u1',
  email: 'ana@test.com',
  first_name: 'Ana',
  last_name: 'Paz',
  role: 'artist',
  is_verified: true,
  phone: '300',
} as User

describe('UserProfilePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ user: USER, isAuthenticated: true })
  })

  it('sin usuario no pinta nada', () => {
    useAuthStore.setState({ user: null })
    renderWithProviders(<UserProfilePage />)
    expect(screen.queryByText('Mi perfil')).not.toBeInTheDocument()
  })

  it('muestra los datos del usuario, su rol y la insignia de verificado', () => {
    renderWithProviders(<UserProfilePage />)
    expect(screen.getByText('Ana Paz')).toBeInTheDocument()
    expect(screen.getByText('ana@test.com')).toBeInTheDocument()
    expect(screen.getByText('Artista')).toBeInTheDocument()
    expect(screen.getByText('Verificado')).toBeInTheDocument()
    expect(screen.getByLabelText('Nombre')).toHaveValue('Ana')
    expect(screen.getByLabelText('Teléfono')).toHaveValue('300')
    expect(screen.getByRole('button', { name: 'Guardar cambios' })).toBeDisabled()
  })

  it('usuario sin verificar, sin teléfono y con rol desconocido', () => {
    useAuthStore.setState({ user: { ...USER, is_verified: false, phone: undefined, role: 'otro' as User['role'], first_name: '' } })
    renderWithProviders(<UserProfilePage />)
    expect(screen.queryByText('Verificado')).not.toBeInTheDocument()
    expect(screen.getByText('otro')).toBeInTheDocument()
    expect(screen.getByLabelText('Teléfono')).toHaveValue('')
  })

  it('guarda los cambios, actualiza la sesión y avisa', async () => {
    mockedUpdate.mockResolvedValue({ ...USER, first_name: 'Anita', phone: undefined })
    renderWithProviders(<UserProfilePage />)
    fireEvent.change(screen.getByLabelText('Nombre'), { target: { value: 'Anita' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar cambios' }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Perfil actualizado correctamente'))
    expect(mockedUpdate.mock.calls[0][0]).toEqual({ first_name: 'Anita', last_name: 'Paz', phone: '300' })
    expect(useAuthStore.getState().user?.first_name).toBe('Anita')
  })

  it('valida que nombre y apellido sean obligatorios', async () => {
    renderWithProviders(<UserProfilePage />)
    fireEvent.change(screen.getByLabelText('Nombre'), { target: { value: ' ' } })
    fireEvent.change(screen.getByLabelText('Apellido'), { target: { value: '' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar cambios' }))
    expect(await screen.findAllByText('Requerido')).toHaveLength(2)
    expect(mockedUpdate).not.toHaveBeenCalled()
  })

  it('si guardar falla muestra el error', async () => {
    mockedUpdate.mockRejectedValue(new Error('Servidor caído'))
    renderWithProviders(<UserProfilePage />)
    fireEvent.change(screen.getByLabelText('Apellido'), { target: { value: 'Otro' } })
    fireEvent.click(screen.getByRole('button', { name: 'Guardar cambios' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith(expect.any(String)))
  })

  it('sube la foto de perfil y actualiza al usuario', async () => {
    mockedAvatar.mockResolvedValue({ ...USER, avatar_url: 'https://img.test/nueva.jpg' })
    renderWithProviders(<UserProfilePage />)
    fireEvent.click(screen.getByRole('button', { name: /subir-foto:Ana:undefined/ }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Foto de perfil actualizada'))
    expect(mockedAvatar.mock.calls[0][0]).toBeInstanceOf(File)
    expect(useAuthStore.getState().user?.avatar_url).toBe('https://img.test/nueva.jpg')
  })

  it('usa el correo como nombre del avatar si no hay nombre, y pasa la foto actual', () => {
    useAuthStore.setState({ user: { ...USER, first_name: '', avatar_url: 'https://img.test/a.jpg' } })
    renderWithProviders(<UserProfilePage />)
    expect(screen.getByRole('button', { name: /subir-foto:ana@test.com:https:\/\/img.test\/a.jpg/ })).toBeInTheDocument()
  })

  it('si subir la foto falla avisa', async () => {
    mockedAvatar.mockRejectedValue(new Error('x'))
    renderWithProviders(<UserProfilePage />)
    fireEvent.click(screen.getByRole('button', { name: /subir-foto/ }))
    await waitFor(() => expect(toast.error).toHaveBeenCalled())
  })
})
