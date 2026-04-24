import { axiosInstance } from '@/api/axiosInstance'
import type { AuthTokens, BackendMeUser, BackendRole } from '@/types/auth'
import { mapBackendMeUser } from '@/types/auth'

export interface LoginPayload {
  email: string
  password: string
}

export async function login(payload: LoginPayload) {
  const { data } = await axiosInstance.post<AuthTokens>('/auth/login/', payload)
  return data
}

export interface RegisterPayload {
  email: string
  password: string
  first_name: string
  last_name: string
  role: BackendRole
  phone?: string
  avatar_url?: string
}

export async function register(payload: RegisterPayload) {
  const { data } = await axiosInstance.post<{ detail: string }>('/auth/register/', payload)
  return data
}

export async function verifyEmail(token: string) {
  const { data } = await axiosInstance.post<{ detail: string }>('/auth/verify-email/', { token })
  return data
}

export async function me() {
  const { data } = await axiosInstance.get<BackendMeUser>('/users/me/')
  return mapBackendMeUser(data)
}

export async function logout(refresh: string) {
  const { data } = await axiosInstance.post<{ detail: string }>('/auth/logout/', { refresh })
  return data
}

export async function requestPasswordReset(email: string) {
  const { data } = await axiosInstance.post<{ detail: string }>('/auth/password-reset/', { email })
  return data
}

export async function confirmPasswordReset(payload: { token: string; new_password: string }) {
  const { data } = await axiosInstance.post<{ detail: string }>(
    '/auth/password-reset/confirm/',
    payload,
  )
  return data
}

