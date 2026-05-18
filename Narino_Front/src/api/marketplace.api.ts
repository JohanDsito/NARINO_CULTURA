import axiosInstance from './axiosInstance'
import type { Artwork, Order } from '@/types/auth'

export interface CartItem {
  id: number
  artwork: Artwork
  quantity: number
  total: number
}

export interface AddCartItemPayload {
  artwork: number
  quantity: number
}

export interface UpdateCartItemPayload {
  quantity: number
}

export async function getCart() {
  const { data } = await axiosInstance.get<CartItem[]>('/api/v1/marketplace/cart/')
  return data
}

export async function addCartItem(payload: AddCartItemPayload) {
  const { data } = await axiosInstance.post<CartItem>('/api/v1/marketplace/cart/items/', payload)
  return data
}

export async function updateCartItem(itemId: string | number, payload: UpdateCartItemPayload) {
  const { data } = await axiosInstance.patch<CartItem>(`/api/v1/marketplace/cart/items/${itemId}/`, payload)
  return data
}

export async function removeCartItem(itemId: string | number) {
  const { data } = await axiosInstance.delete<{ success: boolean }>(`/api/v1/marketplace/cart/items/${itemId}/`)
  return data
}

export async function checkout(payload: Record<string, unknown>) {
  const { data } = await axiosInstance.post<Record<string, unknown>>('/api/v1/marketplace/checkout/', payload)
  return data
}

export async function getOrders() {
  const { data } = await axiosInstance.get<Order[]>('/api/v1/marketplace/orders/')
  return data
}

export async function getSales() {
  const { data } = await axiosInstance.get<Order[]>('/api/v1/marketplace/sales/')
  return data
}

export async function getFavorites() {
  const { data } = await axiosInstance.get<Artwork[]>('/api/v1/marketplace/favorites/')
  return data
}
