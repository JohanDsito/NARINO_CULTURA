import axiosInstance from './axiosInstance'
import type { Artwork, Order, User } from '@/types/auth'

export interface AdminMetrics {
  total_users: number
  total_artworks: number
  total_transactions: number
  new_users_last_30_days: number
  revenue_last_30_days: number
}

export async function getAdminUser(uuid: string) {
  const { data } = await axiosInstance.get<User>(`/api/v1/admin/users/${uuid}/`)
  return data
}

export async function getPendingArtworks() {
  const { data } = await axiosInstance.get<Artwork[]>('/api/v1/admin/artworks/pending/')
  return data
}

export async function moderateArtwork(uuid: string, payload: { status: string; reason?: string }) {
  const { data } = await axiosInstance.post<Artwork>(`/api/v1/admin/artworks/${uuid}/moderate/`, payload)
  return data
}

export async function getAdminTransactions() {
  const { data } = await axiosInstance.get<Order[]>('/api/v1/admin/transactions/')
  return data
}

export async function getAdminNotificationsLog() {
  const { data } = await axiosInstance.get<Record<string, unknown>[]>('/api/v1/admin/notifications/log/')
  return data
}

export async function getAdminMetrics() {
  const { data } = await axiosInstance.get<AdminMetrics>('/api/v1/admin/metrics/')
  return data
}
