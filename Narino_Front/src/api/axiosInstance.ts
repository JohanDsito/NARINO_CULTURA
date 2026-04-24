import axios, { type AxiosError, type InternalAxiosRequestConfig } from 'axios'

import { useAuthStore } from '@/store/authStore'

const baseURL = (import.meta.env.VITE_API_BASE_URL ?? '').replace(/\/$/, '')

export const axiosInstance = axios.create({
  baseURL,
  headers: { 'Content-Type': 'application/json' },
})

function attachAccessToken(config: InternalAxiosRequestConfig) {
  const token = useAuthStore.getState().accessToken
  if (token) {
    config.headers = config.headers ?? {}
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
}

axiosInstance.interceptors.request.use(attachAccessToken)

let isRefreshing = false
let refreshQueue: Array<(newAccessToken: string | null) => void> = []

function resolveRefreshQueue(newAccessToken: string | null) {
  refreshQueue.forEach((cb) => cb(newAccessToken))
  refreshQueue = []
}

async function refreshAccessToken(refreshToken: string) {
  const refreshAxios = axios.create({ baseURL, headers: { 'Content-Type': 'application/json' } })
  const response = await refreshAxios.post<{ access: string }>('/auth/token/refresh/', {
    refresh: refreshToken,
  })
  return response.data.access
}

axiosInstance.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as (InternalAxiosRequestConfig & { _retry?: boolean }) | undefined
    const status = error.response?.status

    if (!originalRequest || status !== 401) {
      return Promise.reject(error)
    }

    const isRefreshEndpoint = originalRequest.url?.includes('/auth/token/refresh/')
    if (isRefreshEndpoint) {
      useAuthStore.getState().logout()
      window.location.href = '/login'
      return Promise.reject(error)
    }

    if (originalRequest._retry) {
      return Promise.reject(error)
    }

    const currentRefreshToken = useAuthStore.getState().refreshToken
    if (!currentRefreshToken) {
      useAuthStore.getState().logout()
      window.location.href = '/login'
      return Promise.reject(error)
    }

    originalRequest._retry = true

    if (isRefreshing) {
      return await new Promise((resolve, reject) => {
        refreshQueue.push((newAccessToken) => {
          if (!newAccessToken) {
            reject(error)
            return
          }
          originalRequest.headers = originalRequest.headers ?? {}
          originalRequest.headers.Authorization = `Bearer ${newAccessToken}`
          resolve(axiosInstance(originalRequest))
        })
      })
    }

    isRefreshing = true
    try {
      const newAccessToken = await refreshAccessToken(currentRefreshToken)
      useAuthStore.getState().setAccessToken(newAccessToken)
      resolveRefreshQueue(newAccessToken)
      originalRequest.headers = originalRequest.headers ?? {}
      originalRequest.headers.Authorization = `Bearer ${newAccessToken}`
      return await axiosInstance(originalRequest)
    } catch (refreshError) {
      resolveRefreshQueue(null)
      useAuthStore.getState().logout()
      window.location.href = '/login'
      return Promise.reject(refreshError)
    } finally {
      isRefreshing = false
    }
  },
)
