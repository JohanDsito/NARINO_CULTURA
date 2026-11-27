import axiosInstance from './axiosInstance'
import { mapRoleToBackendRole, normalizeUser, type Artwork, type User, type UserRole } from '@/types'
import type { Event } from './events.api'

export interface AdminMetrics {
  total_users: number
  total_artworks: number
  total_transactions: number
  new_users_last_30_days: number
  revenue_last_30_days: number
}

export interface AdminUserListItem extends User {
  is_active: boolean
}

/** Fila de `GET /admin/artworks/pending/` (la vista no usa ArtworkSerializer). */
export interface PendingArtwork {
  id: string
  title: string
  artist_slug: string
  price: string
  created_at: string
}

/** Fila de `GET /admin/transactions/`: una transacción con datos de su orden. */
export interface AdminTransaction {
  id: string
  order_id: string
  buyer_email: string
  amount: string
  currency: string
  status: 'PENDIENTE' | 'APROBADO' | 'RECHAZADO' | 'REEMBOLSADO'
  total_amount: string
  order_type: 'COMPRA_DIRECTA' | 'SUBASTA'
  order_status: string
  created_at: string
}

// ── Metrics ───────────────────────────────────────────────────────────────────

export async function getAdminMetrics() {
  const { data } = await axiosInstance.get<AdminMetrics>('/api/v1/admin/metrics/')
  return data
}

// ── Users ─────────────────────────────────────────────────────────────────────

/** Filtros del listado: el backend acepta `role` (valor del backend), `is_active` y `search`. */
export interface AdminUserFilters {
  role?: UserRole
  is_active?: boolean
}

export async function listAdminUsers(filters: AdminUserFilters = {}): Promise<AdminUserListItem[]> {
  const params: Record<string, string> = {}
  if (filters.role) params.role = mapRoleToBackendRole(filters.role)
  if (filters.is_active !== undefined) params.is_active = String(filters.is_active)
  const { data } = await axiosInstance.get<AdminUserListItem[]>('/api/v1/admin/users/', { params })
  // El backend envía roles en mayúsculas (ARTISTA, ADMINISTRADOR...): se normalizan
  return data.map((user) => normalizeUser(user) as AdminUserListItem)
}

export async function getAdminUser(uuid: string) {
  const { data } = await axiosInstance.get<User>(`/api/v1/admin/users/${uuid}/`)
  return data
}

/** Cambia el rol y/o suspende (`is_active: false`) o restaura (`true`) a un usuario. */
export async function updateAdminUser(
  uuid: string,
  payload: { role?: UserRole; is_active?: boolean },
): Promise<AdminUserListItem> {
  const body: Record<string, unknown> = {}
  if (payload.role) body.role = mapRoleToBackendRole(payload.role)
  if (payload.is_active !== undefined) body.is_active = payload.is_active
  const { data } = await axiosInstance.patch<AdminUserListItem>(`/api/v1/admin/users/${uuid}/`, body)
  return normalizeUser(data) as AdminUserListItem
}

export async function deleteAdminUser(uuid: string): Promise<void> {
  await axiosInstance.delete(`/api/v1/admin/users/${uuid}/`)
}

// ── Artworks ──────────────────────────────────────────────────────────────────

export async function getPendingArtworks(): Promise<PendingArtwork[]> {
  const { data } = await axiosInstance.get<PendingArtwork[]>('/api/v1/admin/artworks/pending/')
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

// Acciones dedicadas: además de publicar, notifican; y `reject` se niega a borrar
// eventos ya publicados (el DELETE genérico que se usaba antes sí los borraba).
export async function approveEvent(id: string): Promise<{ detail: string }> {
  const { data } = await axiosInstance.post<{ detail: string }>(`/api/v1/events/${id}/approve/`)
  return data
}

export async function rejectEvent(id: string): Promise<{ detail: string }> {
  const { data } = await axiosInstance.post<{ detail: string }>(`/api/v1/events/${id}/reject/`)
  return data
}

// ── Transactions ──────────────────────────────────────────────────────────────

export async function getAdminTransactions(): Promise<AdminTransaction[]> {
  const { data } = await axiosInstance.get<AdminTransaction[]>('/api/v1/admin/transactions/')
  return data
}

export async function getAdminNotificationsLog() {
  const { data } = await axiosInstance.get<Record<string, unknown>[]>(
    '/api/v1/admin/notifications/log/',
  )
  return data
}
