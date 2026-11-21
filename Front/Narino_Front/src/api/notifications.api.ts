import axiosInstance from './axiosInstance'
import type { AppNotification, PaginatedResponse } from '@/types'

// Bandeja de notificaciones dentro de la plataforma (backend: apps/notifications)

export interface ListNotificationsParams {
  unread?: boolean
  page?: number
}

export async function listNotifications(
  params: ListNotificationsParams = {},
): Promise<PaginatedResponse<AppNotification>> {
  const { data } = await axiosInstance.get<PaginatedResponse<AppNotification>>(
    '/api/v1/notifications/',
    { params: { unread: params.unread ? 'true' : undefined, page: params.page } },
  )
  return data
}

export async function getUnreadNotificationsCount(): Promise<number> {
  const { data } = await axiosInstance.get<{ unread: number }>('/api/v1/notifications/unread-count/')
  return data.unread
}

export async function markNotificationRead(id: string): Promise<AppNotification> {
  const { data } = await axiosInstance.post<AppNotification>(`/api/v1/notifications/${id}/read/`)
  return data
}

export async function markAllNotificationsRead(): Promise<number> {
  const { data } = await axiosInstance.post<{ updated: number }>('/api/v1/notifications/read-all/')
  return data.updated
}
