import axiosInstance from './axiosInstance'
import type { Order, PaginatedResponse } from '@/types/auth'

// ─── Cart ─────────────────────────────────────────────────────────────────────
// Backend: GET /api/v1/marketplace/cart/ → { id, user, items: [], created_at, updated_at }
export interface ServerCartItem {
  id: string
  artwork: string           // Artwork UUID FK
  artwork_title?: string
  artwork_price?: string
  artwork_status?: string
  artwork_main_image_url?: string
  created_at: string
}

export interface ServerCart {
  id: string
  user: string
  items: ServerCartItem[]
  created_at: string
  updated_at: string
}

export async function getServerCart(): Promise<ServerCart> {
  const { data } = await axiosInstance.get<ServerCart>('/api/v1/marketplace/cart/')
  return data
}

// Backend: POST /api/v1/marketplace/cart/items/ with { artwork_id }
// No quantity — backend enforces one unit per artwork
export async function addCartItem(artworkId: string): Promise<{ detail: string }> {
  const { data } = await axiosInstance.post<{ detail: string }>(
    '/api/v1/marketplace/cart/items/',
    { artwork_id: artworkId },
  )
  return data
}

// Backend: DELETE /api/v1/marketplace/cart/items/ with body { artwork_id }
export async function removeCartItem(artworkId: string): Promise<{ detail: string }> {
  const { data } = await axiosInstance.delete<{ detail: string }>(
    '/api/v1/marketplace/cart/items/',
    { data: { artwork_id: artworkId } },
  )
  return data
}

// ─── Favorites ────────────────────────────────────────────────────────────────
import type { Artwork } from '@/types/auth'

export async function getFavorites(): Promise<Artwork[]> {
  const { data } = await axiosInstance.get<Artwork[] | { results: Artwork[] }>(
    '/api/v1/marketplace/favorites/',
  )
  return Array.isArray(data) ? data : data.results ?? []
}

export async function addFavorite(artworkId: string): Promise<{ detail: string }> {
  const { data } = await axiosInstance.post<{ detail: string }>(
    '/api/v1/marketplace/favorites/',
    { artwork_id: artworkId },
  )
  return data
}

export async function removeFavorite(artworkId: string): Promise<{ detail: string }> {
  const { data } = await axiosInstance.delete<{ detail: string }>(
    '/api/v1/marketplace/favorites/',
    { data: { artwork_id: artworkId } },
  )
  return data
}

// ─── Checkout ─────────────────────────────────────────────────────────────────
// Backend: POST /api/v1/marketplace/checkout/ → { order_id, total_amount }
export async function checkout(
  orderType: 'COMPRA_DIRECTA' | 'SUBASTA' = 'COMPRA_DIRECTA',
): Promise<{ order_id: string; total_amount: string }> {
  const { data } = await axiosInstance.post<{ order_id: string; total_amount: string }>(
    '/api/v1/marketplace/checkout/',
    { order_type: orderType },
  )
  return data
}

// ─── Orders & Sales ───────────────────────────────────────────────────────────
export async function getOrders(): Promise<Order[]> {
  const { data } = await axiosInstance.get<Order[] | PaginatedResponse<Order>>(
    '/api/v1/marketplace/orders/',
  )
  return Array.isArray(data) ? data : data.results ?? []
}

export async function getSales(): Promise<Order[]> {
  const { data } = await axiosInstance.get<Order[] | PaginatedResponse<Order>>(
    '/api/v1/marketplace/sales/',
  )
  return Array.isArray(data) ? data : data.results ?? []
}
