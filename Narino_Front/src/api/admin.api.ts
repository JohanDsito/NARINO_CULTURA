import axiosInstance from './axiosInstance'
import type { Artwork, Order, User } from '@/types/auth'
import type { Event } from './events.api'

export interface AdminMetrics {
  total_users: number
  total_artworks: number
  total_transactions: number
  new_users_last_30_days: number
  revenue_last_30_days: number
}

export interface AdminUserListItem extends User {
  date_joined?: string
  is_active?: boolean
}

// ── Metrics ───────────────────────────────────────────────────────────────────

export async function getAdminMetrics() {
  const { data } = await axiosInstance.get<AdminMetrics>('/api/v1/admin/metrics/')
  return data
}

// ── Users ─────────────────────────────────────────────────────────────────────

export async function listAdminUsers(): Promise<AdminUserListItem[]> {
  try {
    const { data } = await axiosInstance.get<AdminUserListItem[] | { results: AdminUserListItem[] }>(
      '/api/v1/admin/users/',
    )
    return Array.isArray(data) ? data : (data as { results?: AdminUserListItem[] }).results ?? []
  } catch {
    // Fallback: /api/v1/admin/users/ may not be registered on this backend
    const { data } = await axiosInstance.get<AdminUserListItem[] | { results: AdminUserListItem[] }>(
      '/api/v1/users/',
    )
    return Array.isArray(data) ? data : (data as { results?: AdminUserListItem[] }).results ?? []
  }
}

export async function getAdminUser(uuid: string) {
  const { data } = await axiosInstance.get<User>(`/api/v1/admin/users/${uuid}/`)
  return data
}

export async function deleteAdminUser(uuid: string): Promise<void> {
  await axiosInstance.delete(`/api/v1/admin/users/${uuid}/`)
}

// ── Artworks ──────────────────────────────────────────────────────────────────

export async function getPendingArtworks() {
  const { data } = await axiosInstance.get<Artwork[]>('/api/v1/admin/artworks/pending/')
  return data
}

export async function moderateArtwork(uuid: string, payload: { status: string; reason?: string }) {
  const { data } = await axiosInstance.post<Artwork>(
    `/api/v1/admin/artworks/${uuid}/moderate/`,
    payload,
  )
  return data
}

export async function deleteAdminArtwork(uuid: string): Promise<void> {
  await axiosInstance.delete(`/api/v1/artworks/${uuid}/delete/`)
}

export async function getAllArtworks(params?: { status?: string; page?: number }): Promise<Artwork[]> {
  const { data } = await axiosInstance.get<Artwork[] | { results?: Artwork[] }>(
    '/api/v1/artworks/',
    { params },
  )
  return Array.isArray(data) ? data : data.results ?? []
}

// ── Events ────────────────────────────────────────────────────────────────────

export async function getPendingEvents(): Promise<Event[]> {
  const { data } = await axiosInstance.get<Event[] | { results: Event[] }>('/api/v1/events/', {
    params: { is_published: false },
  })
  return Array.isArray(data) ? data : data.results ?? []
}

export async function getApprovedEvents(): Promise<Event[]> {
  const { data } = await axiosInstance.get<Event[] | { results: Event[] }>('/api/v1/events/', {
    params: { is_published: true },
  })
  return Array.isArray(data) ? data : data.results ?? []
}

export async function approveEvent(id: string): Promise<Event> {
  const { data } = await axiosInstance.patch<Event>(`/api/v1/events/${id}/`, {
    is_published: true,
  })
  return data
}

export async function rejectEvent(id: string): Promise<void> {
  await axiosInstance.delete(`/api/v1/events/${id}/`)
}

// ── Transactions ──────────────────────────────────────────────────────────────

export async function getAdminTransactions() {
  const { data } = await axiosInstance.get<Order[]>('/api/v1/admin/transactions/')
  return data
}

export async function getAdminNotificationsLog() {
  const { data } = await axiosInstance.get<Record<string, unknown>[]>(
    '/api/v1/admin/notifications/log/',
  )
  return data
}
