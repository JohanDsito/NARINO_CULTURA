import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { onlineManager } from '@tanstack/react-query'
import { toast } from 'sonner'

import { createArtistProfile } from '@/api/artists.api'
import { login, me, register } from '@/api/auth.api'
import { LoginForm } from '@/components/auth/login-form'
import { ProtectedRoute } from '@/components/auth/protected-route'
import { RegisterForm } from '@/components/auth/register-form'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'
import type { User } from '@/types'
import { getPendingArtistProfile, setPendingArtistProfile } from '@/utils/pendingArtistProfile'

vi.mock('@/api/auth.api', () => ({ login: vi.fn(), register: vi.fn(), me: vi.fn() }))
vi.mock('@/api/artists.api', () => ({ createArtistProfile: vi.fn() }))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn(), message: vi.fn() } }))

const mockedLogin = vi.mocked(login)
const mockedRegister = vi.mocked(register)
const mockedMe = vi.mocked(me)
const mockedCreateProfile = vi.mocked(createArtistProfile)

function loginResponse(role: string, id?: string) {
  return { tokens: { access: 'a', refresh: 'r' }, user: { id, role, first_name: 'Ana' } as User }
}

async function submitLogin() {
  fireEvent.change(screen.getByLabelText('Email'), { target: { value: 'ana@test.com' } })
  fireEvent.change(screen.getByLabelText('Contraseña'), { target: { value: 'secreta' } })
  fireEvent.click(screen.getByRole('button', { name: 'Ingresar' }))
}

describe('LoginForm: destinos por rol y errores', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    useAuthStore.setState({ user: null, accessToken: null, refreshToken: null, isAuthenticated: false })
  })

  it.each([
    ['admin', 'u1', '/admin/dashboard'],
    ['cultural_manager', 'u1', '/events'],
    ['buyer', 'u1', '/marketplace'],
    ['artist', 'u1', '/dashboard'],
    ['artist', undefined, '/dashboard'],
    ['otro', 'u1', '/'],
  ])('rol %s (id %s) lleva a %s', async (role, id, path) => {
    mockedLogin.mockResolvedValue(loginResponse(role, id))
    renderWithProviders(<LoginForm />, { route: '/login', path: '/login' })
    await submitLogin()
    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe(path))
    expect(toast.success).toHaveBeenCalledWith('Bienvenido/a.')
  })

  it('vuelve a la ruta de origen si venía de otra página', async () => {
    mockedLogin.mockResolvedValue(loginResponse('buyer'))
    renderWithProviders(<LoginForm />, { route: '/login', path: '/login', state: { from: '/artworks/9' } })
    await submitLogin()
    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('/artworks/9'))
  })

  it('una artista con perfil pendiente lo crea; si falla avisa y de todos modos lo descarta', async () => {
    setPendingArtistProfile({ artistic_name: 'Ana Art', city: 'Pasto' })
    mockedLogin.mockResolvedValue(loginResponse('artist'))
    mockedCreateProfile.mockResolvedValueOnce({} as never)
    const first = renderWithProviders(<LoginForm />, { route: '/login', path: '/login' })
    await submitLogin()
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Perfil de artista creado.'))
    expect(mockedCreateProfile).toHaveBeenCalledWith({ artistic_name: 'Ana Art', city: 'Pasto' })
    expect(getPendingArtistProfile()).toBeNull()
    first.unmount()

    setPendingArtistProfile({ artistic_name: 'Ana Art', city: 'Pasto' })
    mockedCreateProfile.mockRejectedValueOnce(new Error('x'))
    renderWithProviders(<LoginForm />, { route: '/login', path: '/login' })
    await submitLogin()
    await waitFor(() => expect(toast.message).toHaveBeenCalledWith('Perfil de artista', expect.any(Object)))
    expect(getPendingArtistProfile()).toBeNull()
  })

  it('credenciales rechazadas muestran el error, y mientras espera dice "Ingresando…"', async () => {
    let reject!: (e: Error) => void
    mockedLogin.mockReturnValueOnce(new Promise((_, r) => { reject = r }))
    renderWithProviders(<LoginForm />, { route: '/login', path: '/login' })
    await submitLogin()
    expect(await screen.findByRole('button', { name: 'Ingresar' })).toHaveTextContent('Ingresando…')
    reject(new Error('Credenciales inválidas'))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Credenciales inválidas'))
  })
})

describe('ProtectedRoute: estados de verificación', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({ user: null, accessToken: 'tok', refreshToken: 'r', isAuthenticated: true })
  })

  const renderRoute = () =>
    renderWithProviders(
      <ProtectedRoute allowedRoles={['admin']}>
        <p>contenido-protegido</p>
      </ProtectedRoute>,
      { route: '/admin', path: '/admin' },
    )

  it('si no se puede verificar la sesión, la cierra y lleva al login, sin avisos de React', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => {})
    mockedMe.mockRejectedValue(new Error('401'))
    renderRoute()
    await waitFor(() => expect(screen.getByTestId('location')).toHaveTextContent('/login'))
    expect(useAuthStore.getState().accessToken).toBeNull()
    const reactWarnings = consoleError.mock.calls.filter((call) => String(call[0]).includes('Cannot update a component'))
    expect(reactWarnings).toEqual([])
    consoleError.mockRestore()
  })

  it('sin conexión la verificación queda en pausa y se muestra "Cargando perfil…"', async () => {
    onlineManager.setOnline(false)
    try {
      renderRoute()
      expect(await screen.findByText('Cargando perfil…')).toBeInTheDocument()
      expect(screen.queryByText('contenido-protegido')).not.toBeInTheDocument()
      expect(mockedMe).not.toHaveBeenCalled()
    } finally {
      onlineManager.setOnline(true)
    }
  })

  it('trae el perfil del servidor si solo hay token y respeta el rol', async () => {
    mockedMe.mockResolvedValue({
      id: 'u', email: 'admin@test.com', first_name: 'Ada', last_name: 'Min', role: 'admin',
    } as User)
    renderRoute()
    expect(await screen.findByText('contenido-protegido')).toBeInTheDocument()
    await waitFor(() => expect(useAuthStore.getState().user?.role).toBe('admin'))
  })
})

describe('RegisterForm: validaciones y perfil de artista', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  function fillBase() {
    fireEvent.change(screen.getByLabelText('Nombre'), { target: { value: 'Ana' } })
    fireEvent.change(screen.getByLabelText('Apellido'), { target: { value: 'Paz' } })
    fireEvent.change(screen.getByLabelText('Email'), { target: { value: 'ana@test.com' } })
    fireEvent.change(screen.getByLabelText('Contraseña'), { target: { value: 'Clave1234' } })
    fireEvent.change(screen.getByLabelText('Confirmar contraseña'), { target: { value: 'Clave1234' } })
    fireEvent.click(screen.getByRole('checkbox'))
  }

  it('muestra los errores de cada campo obligatorio', async () => {
    renderWithProviders(<RegisterForm />)
    fireEvent.change(screen.getByLabelText('Email'), { target: { value: 'mal' } })
    fireEvent.submit(screen.getByRole('form', { name: 'Formulario de registro' }))
    expect(await screen.findByText('El nombre es obligatorio.')).toBeInTheDocument()
    expect(screen.getByText('El apellido es obligatorio.')).toBeInTheDocument()
    expect(screen.getByText('Ingresa un email válido.')).toBeInTheDocument()
    expect(screen.getByText('Debes aceptar los términos y la política de privacidad.')).toBeInTheDocument()
    expect(mockedRegister).not.toHaveBeenCalled()
  })

  it('una artista debe indicar nombre artístico y ciudad', async () => {
    renderWithProviders(<RegisterForm />)
    fillBase()
    fireEvent.change(screen.getByLabelText('Seleccionar tipo de usuario'), { target: { value: 'artist' } })
    fireEvent.submit(screen.getByRole('form', { name: 'Formulario de registro' }))
    expect(await screen.findByText('El nombre artístico es obligatorio.')).toBeInTheDocument()
    expect(screen.getByText('La ciudad es obligatoria.')).toBeInTheDocument()
    expect(mockedRegister).not.toHaveBeenCalled()
  })

  it('una artista queda con su perfil pendiente (recortado, con categoría y ciudad) y vuelve al login', async () => {
    mockedRegister.mockResolvedValue({ message: 'Revisa tu correo' })
    renderWithProviders(<RegisterForm />, { route: '/register', path: '/register' })
    fillBase()
    fireEvent.change(screen.getByLabelText('Seleccionar tipo de usuario'), { target: { value: 'artist' } })
    fireEvent.change(screen.getByLabelText('Nombre artístico*'), { target: { value: '  Ana Art ' } })
    fireEvent.change(screen.getByLabelText('Ciudad*'), { target: { value: ' Pasto ' } })
    fireEvent.change(screen.getByLabelText('Categoría (opt.)'), { target: { value: ' Pintura ' } })
    fireEvent.click(screen.getByRole('button', { name: 'Crear cuenta' }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Registro exitoso.', { description: 'Revisa tu correo' }))
    expect(getPendingArtistProfile()).toEqual({ artistic_name: 'Ana Art', discipline: 'Pintura', city: 'Pasto' })
    expect(mockedRegister.mock.calls[0][0]).toMatchObject({ role: 'ARTISTA', first_name: 'Ana', last_name: 'Paz' })
    await waitFor(() => expect(screen.getByTestId('location').textContent).toBe('/login'))
  })

  it('una visitante no deja perfil pendiente', async () => {
    mockedRegister.mockResolvedValue({ message: 'ok' })
    renderWithProviders(<RegisterForm />)
    fillBase()
    fireEvent.click(screen.getByRole('button', { name: 'Crear cuenta' }))
    await waitFor(() => expect(mockedRegister).toHaveBeenCalled())
    expect(getPendingArtistProfile()).toBeNull()
    expect(mockedRegister.mock.calls[0][0]).toMatchObject({ role: 'COMPRADOR' })
  })

  it('contraseñas distintas muestran la alerta y el aviso', async () => {
    renderWithProviders(<RegisterForm />)
    fillBase()
    fireEvent.change(screen.getByLabelText('Confirmar contraseña'), { target: { value: 'Otra12345' } })
    fireEvent.submit(screen.getByRole('form', { name: 'Formulario de registro' }))
    expect(await screen.findByRole('alert')).toHaveTextContent('Las contraseñas no coinciden.')
    expect(toast.error).toHaveBeenCalledWith('Las contraseñas no coinciden.')
  })

  it('si el registro falla muestra el error; mientras espera dice "Creando…"', async () => {
    let reject!: (e: Error) => void
    mockedRegister.mockReturnValueOnce(new Promise((_, r) => { reject = r }))
    renderWithProviders(<RegisterForm />)
    fillBase()
    fireEvent.click(screen.getByRole('button', { name: 'Crear cuenta' }))
    expect(await screen.findByRole('button', { name: 'Crear cuenta' })).toHaveTextContent('Creando…')
    reject(new Error('Correo en uso'))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Correo en uso'))
  })
})

describe('RegisterForm: tipo de usuario inválido', () => {
  it('si el tipo de usuario no es ninguno de los ofrecidos muestra el error y no registra', async () => {
    vi.clearAllMocks()
    renderWithProviders(<RegisterForm />)
    fireEvent.change(screen.getByLabelText('Seleccionar tipo de usuario'), { target: { value: 'otro' } })
    fireEvent.submit(screen.getByRole('form', { name: 'Formulario de registro' }))
    expect(await screen.findByText('Selecciona un tipo de usuario.')).toBeInTheDocument()
    expect(mockedRegister).not.toHaveBeenCalled()
  })

  it('una artista sin categoría deja el perfil pendiente con la disciplina indefinida', async () => {
    vi.clearAllMocks()
    localStorage.clear()
    mockedRegister.mockResolvedValue({ message: 'ok' })
    renderWithProviders(<RegisterForm />)
    fireEvent.change(screen.getByLabelText('Nombre'), { target: { value: 'Ana' } })
    fireEvent.change(screen.getByLabelText('Apellido'), { target: { value: 'Paz' } })
    fireEvent.change(screen.getByLabelText('Email'), { target: { value: 'ana@test.com' } })
    fireEvent.change(screen.getByLabelText('Contraseña'), { target: { value: 'Clave1234' } })
    fireEvent.change(screen.getByLabelText('Confirmar contraseña'), { target: { value: 'Clave1234' } })
    fireEvent.click(screen.getByRole('checkbox'))
    fireEvent.change(screen.getByLabelText('Seleccionar tipo de usuario'), { target: { value: 'artist' } })
    fireEvent.change(screen.getByLabelText('Nombre artístico*'), { target: { value: 'Ana Art' } })
    fireEvent.change(screen.getByLabelText('Ciudad*'), { target: { value: 'Pasto' } })
    fireEvent.click(screen.getByRole('button', { name: 'Crear cuenta' }))
    await waitFor(() => expect(mockedRegister).toHaveBeenCalled())
    expect(getPendingArtistProfile()).toEqual({ artistic_name: 'Ana Art', city: 'Pasto' })
  })
})