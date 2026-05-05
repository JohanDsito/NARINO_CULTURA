import axiosInstance from './axiosInstance'
import { normalizeUser, type AuthTokens, type LoginCredentials, type RegisterData, type User } from '@/types/auth'

export async function login(
  credentials: LoginCredentials,
): Promise<{ tokens: AuthTokens; user: User }> {
  const { data } = await axiosInstance.post('/api/v1/auth/login/', credentials)
  const tokens: AuthTokens = data.tokens ?? { access: data.access, refresh: data.refresh }

  if (!tokens.access || !tokens.refresh) {
    throw new Error('Respuesta de autenticación inválida.')
  }

  if (data.user) {
    return { tokens, user: normalizeUser(data.user) as User }
  }

  const { data: user } = await axiosInstance.get('/api/v1/auth/me/', {
    headers: { Authorization: `Bearer ${tokens.access}` },
  })

  return { tokens, user: normalizeUser(user) as User }
}

export async function register(userData: RegisterData): Promise<{ message: string }> {
  const { data } = await axiosInstance.post('/api/v1/auth/register/', userData)
  return { message: data.message ?? data.detail ?? 'Registro exitoso.' }
}

export async function me(): Promise<User> {
  const { data } = await axiosInstance.get('/api/v1/auth/me/')
  return normalizeUser(data) as User
}

export async function requestPasswordReset(
  email: string,
): Promise<{ message: string }> {
  const { data } = await axiosInstance.post('/api/v1/auth/password/reset/', { email })
  return data
}

export async function confirmPasswordReset(
  token: string,
  password: string,
): Promise<{ message: string }> {
  const { data } = await axiosInstance.post('/api/v1/auth/password/reset/confirm/', {
    token,
    new_password: password,
  })
  return data
}

export async function logout(): Promise<void> {
  const refresh = localStorage.getItem('refresh_token')
  if (refresh) {
    await axiosInstance.post('/api/v1/auth/logout/', { refresh }).catch(() => {})
  }
}

export const authApi = {
  login,
  register,
  getMe: me,
  forgotPassword: requestPasswordReset,
  resetPassword: confirmPasswordReset,
  logout,
}
