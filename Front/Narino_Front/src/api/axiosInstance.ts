import axios from 'axios'

import { API_BASE_URL } from '@/config/env'

const axiosInstance = axios.create({
  baseURL: API_BASE_URL,
  headers: { 'Content-Type': 'application/json' },
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

// Response interceptor: refresco automático en 401
axiosInstance.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config

    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true
      const refreshToken = localStorage.getItem('refresh_token')

      if (!refreshToken) {
        localStorage.removeItem('access_token')
        localStorage.removeItem('refresh_token')
        window.location.href = '/login'
        return Promise.reject(error)
      }

      try {
        const { data } = await axios.post(
          `${API_BASE_URL}/api/v1/auth/token/refresh/`,
          { refresh: refreshToken }
        )
        localStorage.setItem('access_token', data.access)
        originalRequest.headers.Authorization = `Bearer ${data.access}`
        return axiosInstance(originalRequest)
      } catch {
        localStorage.removeItem('access_token')
        localStorage.removeItem('refresh_token')
        window.location.href = '/login'
        return Promise.reject(error)
      }
    }

    return Promise.reject(error)
  }
)

export default axiosInstance
