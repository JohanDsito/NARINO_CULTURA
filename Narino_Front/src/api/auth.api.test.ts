import axiosInstance from '@/api/axiosInstance'
import {
  confirmPasswordReset,
  login,
  logout,
  me,
  register,
  requestPasswordReset,
  verifyEmail,
} from '@/api/auth.api'

jest.mock('@/api/axiosInstance', () => ({
  __esModule: true,
  default: {
    get: jest.fn(),
    post: jest.fn(),
  },
}))

const mockedAxios = jest.mocked(axiosInstance)

describe('auth.api', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    localStorage.clear()
  })

  it('logs in with tokens and user returned by the backend', async () => {
    mockedAxios.post.mockResolvedValueOnce({
      data: {
        access: 'access-token',
        refresh: 'refresh-token',
        user: { id: 1, email: 'a@test.com', first_name: 'Ana', last_name: 'Mora', role: 'ARTISTA' },
      },
    })

    await expect(login({ email: 'a@test.com', password: 'secret' })).resolves.toMatchObject({
      tokens: { access: 'access-token', refresh: 'refresh-token' },
      user: { role: 'artist' },
    })
  })

  it('loads the user from /me when login does not include a user', async () => {
    mockedAxios.post.mockResolvedValueOnce({ data: { access: 'a', refresh: 'r' } })
    mockedAxios.get.mockResolvedValueOnce({
      data: { id: 2, email: 'b@test.com', first_name: 'Beto', last_name: 'Paz', role: 'COMPRADOR' },
    })

    const result = await login({ email: 'b@test.com', password: 'secret' })

    expect(mockedAxios.get).toHaveBeenCalledWith('/api/v1/auth/me/', {
      headers: { Authorization: 'Bearer a' },
    })
    expect(result.user.role).toBe('buyer')
  })

  it('rejects invalid login token responses', async () => {
    mockedAxios.post.mockResolvedValueOnce({ data: { access: 'a' } })

    await expect(login({ email: 'a@test.com', password: 'secret' })).rejects.toThrow(
      'Respuesta de autenticación inválida.',
    )
  })

  it('wraps message responses for auth flows', async () => {
    mockedAxios.post
      .mockResolvedValueOnce({ data: { detail: 'Registro OK' } })
      .mockResolvedValueOnce({ data: { detail: 'Email OK' } })
      .mockResolvedValueOnce({ data: { message: 'Reset OK' } })
      .mockResolvedValueOnce({ data: { message: 'Confirm OK' } })

    await expect(register({ email: 'a@test.com', password: 'secret123', first_name: 'Ana', last_name: 'Mora', role: 'buyer' })).resolves.toEqual({ message: 'Registro OK' })
    await expect(verifyEmail('token')).resolves.toEqual({ message: 'Email OK' })
    await expect(requestPasswordReset('a@test.com')).resolves.toEqual({ message: 'Reset OK' })
    await expect(confirmPasswordReset('token', 'secret123')).resolves.toEqual({ message: 'Confirm OK' })
  })

  it('normalizes the current user and posts refresh token on logout', async () => {
    mockedAxios.get.mockResolvedValueOnce({
      data: { id: 1, email: 'a@test.com', first_name: 'Ana', last_name: 'Mora', role: 'ADMINISTRADOR' },
    })
    localStorage.setItem('refresh_token', 'refresh-token')
    mockedAxios.post.mockResolvedValueOnce({ data: {} })

    await expect(me()).resolves.toMatchObject({ role: 'admin' })
    await logout()

    expect(mockedAxios.post).toHaveBeenCalledWith('/api/v1/auth/logout/', {
      refresh: 'refresh-token',
    })
  })
})
