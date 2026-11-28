import { describe, it, expect, beforeEach, vi } from 'vitest'

const mockRequestUse = vi.fn()
const mockResponseUse = vi.fn()
const mockAxiosPost = vi.fn()

const mockAxiosInstance = Object.assign(vi.fn(), {
  interceptors: {
    request: { use: mockRequestUse },
    response: { use: mockResponseUse },
  },
})

vi.mock('axios', () => ({
  default: {
    create: vi.fn(() => mockAxiosInstance),
    post: mockAxiosPost,
  },
}))

describe('axiosInstance', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.stubEnv('VITE_API_BASE_URL', 'http://test-api.local/api/v1')
    localStorage.clear()
    window.history.replaceState(null, '', '/')
    vi.resetModules()
  })

  it('adds bearer token to outgoing requests', async () => {
    await import('./axiosInstance')

    const requestHandler = mockRequestUse.mock.calls[0][0] as (
      config: {
        headers: Record<string, string>
      }
    ) => {
      headers: Record<string, string>
    }

    localStorage.setItem('access_token', 'access-token')

    expect(
      requestHandler({ headers: {} }).headers.Authorization
    ).toBe('Bearer access-token')
  })

  it('refreshes tokens and retries once on 401 responses', async () => {
    await import('./axiosInstance')

    const responseErrorHandler = mockResponseUse.mock.calls[0][1] as (
      error: {
        config: {
          headers: Record<string, string>
          _retry?: boolean
        }
        response: {
          status: number
        }
      }
    ) => Promise<unknown>

    const originalRequest = {
      headers: {} as Record<string, string>,
      _retry: false,
    }

    localStorage.setItem('refresh_token', 'refresh-token')

    mockAxiosPost.mockResolvedValueOnce({
      data: {
        access: 'new-access',
      },
    })

    mockAxiosInstance.mockResolvedValueOnce({
      data: 'ok',
    })

    await expect(
      responseErrorHandler({
        config: originalRequest,
        response: {
          status: 401,
        },
      }),
    ).resolves.toEqual({
      data: 'ok',
    })

    expect(mockAxiosPost).toHaveBeenCalledWith(
      'http://test-api.local/api/v1/auth/token/refresh/',
      {
        refresh: 'refresh-token',
      },
    )

    expect(localStorage.getItem('access_token')).toBe(
      'new-access',
    )

    expect(originalRequest.headers.Authorization).toBe(
      'Bearer new-access',
    )

    expect(mockAxiosInstance).toHaveBeenCalledWith(
      originalRequest,
    )
  })

  it('clears tokens when refresh is unavailable', async () => {
    await import('./axiosInstance')

    const responseErrorHandler = mockResponseUse.mock.calls[0][1] as (
      error: {
        config: {
          headers: Record<string, string>
          _retry?: boolean
        }
        response: {
          status: number
        }
      }
    ) => Promise<unknown>

    localStorage.setItem('access_token', 'access-token')

    await expect(
      responseErrorHandler({
        config: {
          headers: {},
          _retry: false,
        },
        response: {
          status: 401,
        },
      }),
    ).rejects.toBeTruthy()

    expect(localStorage.getItem('access_token')).toBeNull()

    expect(localStorage.getItem('refresh_token')).toBeNull()
  })

  it('guarda el refresh rotado en localStorage y en el store', async () => {
    await import('./axiosInstance')
    const { useAuthStore } = await import('@/store/authStore')
    const handler = mockResponseUse.mock.calls[0][1] as (e: unknown) => Promise<unknown>
    localStorage.setItem('refresh_token', 'refresh-viejo')
    mockAxiosPost.mockResolvedValueOnce({ data: { access: 'a2', refresh: 'refresh-nuevo' } })
    mockAxiosInstance.mockResolvedValueOnce({ data: 'ok' })

    await handler({ config: { headers: {}, _retry: false }, response: { status: 401 } })

    expect(localStorage.getItem('refresh_token')).toBe('refresh-nuevo')
    expect(useAuthStore.getState().refreshToken).toBe('refresh-nuevo')
    expect(useAuthStore.getState().accessToken).toBe('a2')
  })

  it('dos 401 simultáneos hacen una sola renovación y ambos reintentan', async () => {
    await import('./axiosInstance')
    const handler = mockResponseUse.mock.calls[0][1] as (e: unknown) => Promise<unknown>
    localStorage.setItem('refresh_token', 'r1')
    let resolvePost!: (v: unknown) => void
    mockAxiosPost.mockReturnValueOnce(new Promise((res) => { resolvePost = res }))
    mockAxiosInstance.mockResolvedValue({ data: 'ok' })
    const reqA = { headers: {} as Record<string, string>, _retry: false }
    const reqB = { headers: {} as Record<string, string>, _retry: false }

    const pA = handler({ config: reqA, response: { status: 401 } })
    const pB = handler({ config: reqB, response: { status: 401 } })
    resolvePost({ data: { access: 'a2', refresh: 'r2' } })
    await Promise.all([pA, pB])

    expect(mockAxiosPost).toHaveBeenCalledTimes(1)
    expect(reqA.headers.Authorization).toBe('Bearer a2')
    expect(reqB.headers.Authorization).toBe('Bearer a2')
    expect(mockAxiosInstance).toHaveBeenCalledTimes(2)
  })

  it('si la renovación falla cierra la sesión y rechaza ambas peticiones', async () => {
    await import('./axiosInstance')
    const handler = mockResponseUse.mock.calls[0][1] as (e: unknown) => Promise<unknown>
    localStorage.setItem('access_token', 'a')
    localStorage.setItem('refresh_token', 'r1')
    mockAxiosPost.mockRejectedValueOnce(new Error('400'))

    const results = await Promise.allSettled([
      handler({ config: { headers: {}, _retry: false }, response: { status: 401 } }),
      handler({ config: { headers: {}, _retry: false }, response: { status: 401 } }),
    ])

    expect(results.every((r) => r.status === 'rejected')).toBe(true)
    expect(mockAxiosPost).toHaveBeenCalledTimes(1)
    expect(localStorage.getItem('refresh_token')).toBeNull()
    expect(localStorage.getItem('access_token')).toBeNull()
  })
})
