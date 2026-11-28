import axios from 'axios'

import { API_BASE_URL } from '@/config/env'
import { useAuthStore } from '@/store/authStore'

const axiosInstance = axios.create({
  baseURL: API_BASE_URL,
  timeout: 15000,
})

// Request interceptor: agrega Bearer token
axiosInstance.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

/** Cierra la sesión local (tokens + store persistido) y manda al login. */
function forceLogout() {
  useAuthStore.getState().logout()
  if (window.location.pathname !== '/login') window.location.href = '/login'
}

/** Renovación en curso: con rotación el refresh viejo queda invalidado, así que
 *  todas las peticiones que reciban 401 esperan esta misma promesa. */
let refreshInFlight: Promise<string> | null = null

function renewAccessToken(refreshToken: string): Promise<string> {
  if (!refreshInFlight) {
    refreshInFlight = axios
      .post(`${API_BASE_URL}/api/v1/auth/token/refresh/`, { refresh: refreshToken })
      .then(({ data }) => {
        localStorage.setItem('access_token', data.access)
        // El backend rota el refresh: hay que guardar el nuevo (el anterior queda en lista negra).
        if (data.refresh) {
          localStorage.setItem('refresh_token', data.refresh)
          useAuthStore.setState({ accessToken: data.access, refreshToken: data.refresh })
        } else {
          useAuthStore.setState({ accessToken: data.access })
        }
        return data.access as string
      })
      .finally(() => {
        refreshInFlight = null
      })
  }
  return refreshInFlight
}

// Response interceptor: refresco automático en 401
axiosInstance.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config

    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true
      const refreshToken = localStorage.getItem('refresh_token')

      if (!refreshToken) {
        forceLogout()
        return Promise.reject(error)
      }

      try {
        const access = await renewAccessToken(refreshToken)
        originalRequest.headers.Authorization = `Bearer ${access}`
        return axiosInstance(originalRequest)
      } catch {
        forceLogout()
        return Promise.reject(error)
      }
    }

    return Promise.reject(error)
  }
)

export default axiosInstance
