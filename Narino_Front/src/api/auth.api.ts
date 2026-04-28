import axiosInstance from './axiosInstance'
import type { AuthTokens, LoginCredentials, RegisterData, User } from '@/types/auth'

export async function login(
  credentials: LoginCredentials,
): Promise<{ tokens: AuthTokens; user: User }> {
  const { data } = await axiosInstance.post('/api/v1/auth/login/', credentials)
  return data
}

export async function register(userData: RegisterData): Promise<{ message: string }> {
  const { data } = await axiosInstance.post('/api/v1/auth/register/', userData)
  return data
}

export async function me(): Promise<User> {
  const { data } = await axiosInstance.get('/api/v1/auth/me/')
  return data
}

export async function requestPasswordReset(
  email: string,
): Promise<{ message: string }> {
  const { data } = await axiosInstance.post('/auth/password/reset/', { email })
  return data
}

export async function confirmPasswordReset(
  token: string,
  password: string,
): Promise<{ message: string }> {
  const { data } = await axiosInstance.post('/auth/password/reset/confirm/', {
    token,
    password,
  })
  return data
}

export async function logout(): Promise<void> {
  const refresh = localStorage.getItem('refresh_token')
  if (refresh) {
    await axiosInstance.post('/auth/logout/', { refresh }).catch(() => {})
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
