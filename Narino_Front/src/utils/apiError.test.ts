import { getApiErrorMessage } from '@/utils/apiError'

function axiosError(data: unknown) {
  return {
    isAxiosError: true,
    response: { data },
  }
}

describe('getApiErrorMessage', () => {
  it('returns plain string API errors', () => {
    expect(getApiErrorMessage(axiosError('Error directo'))).toBe('Error directo')
  })

  it('returns detail from API error objects', () => {
    expect(getApiErrorMessage(axiosError({ detail: 'Token inválido' }))).toBe('Token inválido')
  })

  it('returns first string field from API error objects', () => {
    expect(getApiErrorMessage(axiosError({ email: 'Email inválido' }))).toBe('Email inválido')
  })

  it('returns first string from array field errors', () => {
    expect(getApiErrorMessage(axiosError({ password: ['Muy corta'] }))).toBe('Muy corta')
  })

  it('returns Error messages and generic fallback', () => {
    expect(getApiErrorMessage(new Error('Falló'))).toBe('Falló')
    expect(getApiErrorMessage(null)).toBe('Ocurrió un error inesperado.')
  })
})
