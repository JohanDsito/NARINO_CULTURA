import axiosInstance from './axiosInstance'
import {
  normalizeUser,
  type AuthTokens,
  type LoginCredentials,
  type RegisterData,
  type User,
} from '@/types'

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

  const { data: user } = await axiosInstance.get('/api/v1/users/me/', {
    headers: { Authorization: `Bearer ${tokens.access}` },
  })

  return { tokens, user: normalizeUser(user) as User }
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
  return normalizeUser(data) as User
}

/** El backend responde `{ detail }` en unos endpoints y `{ message }` en otros. */
function toMessage(data: { message?: string; detail?: string } | undefined, fallback: string) {
  return { message: data?.message ?? data?.detail ?? fallback }
}

export async function requestPasswordReset(email: string): Promise<{ message: string }> {
  const { data } = await axiosInstance.post('/api/v1/auth/password-reset/', { email })
  return toMessage(data, 'Si el correo existe, te enviamos instrucciones.')
}

export async function confirmPasswordReset(
  token: string,
  password: string,
): Promise<{ message: string }> {
  const { data } = await axiosInstance.post('/api/v1/auth/password-reset/confirm/', {
    token,
    new_password: password,
  })
  return toMessage(data, 'Contraseña actualizada.')
}

export async function changePassword(currentPassword: string, newPassword: string): Promise<{ message: string }> {
  const { data } = await axiosInstance.post('/api/v1/users/me/password/', {
    current_password: currentPassword,
    new_password: newPassword,
  })
  return toMessage(data, 'Contraseña actualizada.')
}

export interface UpdateMePayload {
  first_name?: string
  last_name?: string
  phone?: string
}

export async function updateMe(payload: UpdateMePayload): Promise<User> {
  const { data } = await axiosInstance.patch('/api/v1/users/me/', payload)
  return normalizeUser(data) as User
}

/** `avatar_url` es de solo lectura: la foto se sube como archivo en el campo `avatar`. */
export async function uploadAvatar(file: File): Promise<User> {
  const formData = new FormData()
  formData.append('avatar', file)
  const { data } = await axiosInstance.patch('/api/v1/users/me/', formData)
  return normalizeUser(data) as User
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
  changePassword,
  updateMe,
  uploadAvatar,
  logout,
}
