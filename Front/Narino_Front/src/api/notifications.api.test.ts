import { describe, it, expect, beforeEach, vi } from 'vitest'
import axiosInstance from './axiosInstance'
import {
  getUnreadNotificationsCount,
  listNotifications,
  markAllNotificationsRead,
  markNotificationRead,
} from './notifications.api'

vi.mock('./axiosInstance', () => ({
  default: { get: vi.fn(), post: vi.fn() },
}))

const mockedAxios = vi.mocked(axiosInstance)

describe('notifications.api', () => {
  beforeEach(() => vi.clearAllMocks())

  it('lista la bandeja y solo manda unread=true cuando se piden las no leídas', async () => {
    const data = { count: 0, next: null, previous: null, results: [] }
    mockedAxios.get.mockResolvedValue({ data })

    await expect(listNotifications()).resolves.toBe(data)
    expect(mockedAxios.get).toHaveBeenLastCalledWith('/api/v1/notifications/', {
      params: { unread: undefined, page: undefined },
    })

    await listNotifications({ unread: true, page: 2 })
    expect(mockedAxios.get).toHaveBeenLastCalledWith('/api/v1/notifications/', {
      params: { unread: 'true', page: 2 },
    })
  })

  it('lee el contador de no leídas', async () => {
    mockedAxios.get.mockResolvedValueOnce({ data: { unread: 4 } })
    await expect(getUnreadNotificationsCount()).resolves.toBe(4)
    expect(mockedAxios.get).toHaveBeenCalledWith('/api/v1/notifications/unread-count/')
  })

  it('marca una y marca todas', async () => {
    mockedAxios.post.mockResolvedValueOnce({ data: { id: 'n1', read: true } })
    await markNotificationRead('n1')
    expect(mockedAxios.post).toHaveBeenCalledWith('/api/v1/notifications/n1/read/')

    mockedAxios.post.mockResolvedValueOnce({ data: { updated: 3 } })
    await expect(markAllNotificationsRead()).resolves.toBe(3)
    expect(mockedAxios.post).toHaveBeenLastCalledWith('/api/v1/notifications/read-all/')
  })
})
