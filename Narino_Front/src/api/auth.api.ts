import axiosInstance from './axiosInstance'
import type { AuthTokens, LoginCredentials, RegisterData, User } from '@/types/auth'

export async function login(
  credentials: LoginCredentials,
): Promise<{ tokens: AuthTokens; user: User }> {
  const { data: tokens } = await axiosInstance.post('/api/v1/auth/login/', credentials)

  localStorage.setItem('access_token', tokens.access)
  localStorage.setItem('refresh_token', tokens.refresh)

  try {
    const user = await me()
    return { tokens, user }
  } catch (error) {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    throw error
  }
}

export async function register(userData: RegisterData): Promise<{ message: string }> {
  const { data } = await axiosInstance.post('/api/v1/auth/register/', userData)
  return { message: data.message ?? data.detail ?? 'Registro exitoso.' }
}

export async function verifyEmail(token: string): Promise<{ message: string }> {
  const { data } = await axiosInstance.post('/api/v1/auth/verify-email/', { token })
  return { message: data.message ?? data.detail ?? 'Email verificado correctamente.' }
}

export async function me(): Promise<User> {
  const { data } = await axiosInstance.get('/api/v1/users/me/')
  return data
}

export async function requestPasswordReset(
  email: string,
): Promise<{ message: string }> {
  const { data } = await axiosInstance.post('/api/v1/auth/password-reset/', { email })
  return { message: data.message ?? data.detail ?? 'Solicitud enviada.' }
}

export async function confirmPasswordReset(
  token: string,
  password: string,
): Promise<{ message: string }> {
  const { data } = await axiosInstance.post('/api/v1/auth/password-reset/confirm/', {
    token,
    new_password: password,
  })
  return { message: data.message ?? data.detail ?? 'Contraseña actualizada correctamente.' }
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
  verifyEmail,
  getMe: me,
  forgotPassword: requestPasswordReset,
  resetPassword: confirmPasswordReset,
  logout,
}
