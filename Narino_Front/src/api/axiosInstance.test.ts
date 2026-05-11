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
})