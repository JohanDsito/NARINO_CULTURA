const DEFAULT_API_BASE_URL = 'https://narinocultura-production.up.railway.app'

const rawApiBaseUrl = import.meta.env.VITE_API_BASE_URL || DEFAULT_API_BASE_URL

export const API_BASE_URL = rawApiBaseUrl
  .replace(/\/+$/, '')
  .replace(/\/api\/v1$/i, '')

// Otras variables de entorno
