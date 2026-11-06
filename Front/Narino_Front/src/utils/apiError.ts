import axios from 'axios'

export function getApiErrorMessage(error: unknown): string {
  if (axios.isAxiosError(error)) {
    const data = error.response?.data as unknown
    if (typeof data === 'string') return data
    if (data && typeof data === 'object') {
      const maybeDetail = (data as { detail?: unknown }).detail
      if (typeof maybeDetail === 'string') return maybeDetail
      const firstKey = Object.keys(data as Record<string, unknown>)[0]
      const value = (data as Record<string, unknown>)[firstKey]
      if (typeof value === 'string') return value
      if (Array.isArray(value) && typeof value[0] === 'string') return value[0]
    }
    return 'No fue posible completar la solicitud.'
  }
  if (error instanceof Error) return error.message
  return 'Ocurrió un error inesperado.'
}

