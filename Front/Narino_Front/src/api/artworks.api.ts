import axiosInstance from './axiosInstance'
import type { Artwork, PaginatedResponse } from '@/types/auth'

export interface ArtworkCategoryItem {
  id: number
  name: string
  slug?: string
  description?: string
}

export interface GetArtworksParams {
  category?: string | number
  artist?: string
  search?: string
  ordering?: string
  status?: string
  page?: number
  page_size?: number
}

export interface CreateArtworkPayload {
  title: string
  description: string
  category?: number           // FK id to Category model
  price?: number
  technique?: string
  dimensions?: string
  material?: string
  main_image?: File           // FileField — backend path: artworks/covers/
}

export async function getArtworks(
  params?: GetArtworksParams,
): Promise<PaginatedResponse<Artwork>> {
  const { data } = await axiosInstance.get<PaginatedResponse<Artwork> | Artwork[]>(
    '/api/v1/artworks/',
    { params },
  )
  if (Array.isArray(data)) {
    return { count: data.length, next: null, previous: null, results: data }
  }
  return data
}

export async function createArtwork(payload: CreateArtworkPayload): Promise<Artwork> {
  const formData = new FormData()
  formData.append('title', payload.title)
  formData.append('description', payload.description)
  if (payload.category !== undefined) formData.append('category', String(payload.category))
  if (payload.price !== undefined) formData.append('price', String(payload.price))
  if (payload.technique) formData.append('technique', payload.technique)
  if (payload.dimensions) formData.append('dimensions', payload.dimensions)
  if (payload.material) formData.append('material', payload.material)
  if (payload.main_image) formData.append('main_image', payload.main_image)

  const { data } = await axiosInstance.post<Artwork>('/api/v1/artworks/', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  })
  return data
}

export async function getArtworkById(id: string | number): Promise<Artwork> {
  const { data } = await axiosInstance.get<Artwork>(`/api/v1/artworks/${id}/`)
  return data
}

export async function updateArtwork(
  id: string | number,
  payload: Partial<CreateArtworkPayload>,
): Promise<Artwork> {
  const formData = new FormData()
  if (payload.title) formData.append('title', payload.title)
  if (payload.description) formData.append('description', payload.description)
  if (payload.category !== undefined) formData.append('category', String(payload.category))
  if (payload.price !== undefined) formData.append('price', String(payload.price))
  if (payload.technique) formData.append('technique', payload.technique)
  if (payload.dimensions) formData.append('dimensions', payload.dimensions)
  if (payload.material) formData.append('material', payload.material)
  if (payload.main_image) formData.append('main_image', payload.main_image)

  const { data } = await axiosInstance.patch<Artwork>(`/api/v1/artworks/${id}/`, formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  })
  return data
}

export async function deleteArtwork(id: string | number): Promise<void> {
  await axiosInstance.delete(`/api/v1/artworks/${id}/delete/`)
}

export async function aiEnhanceArtwork(
  id: string | number,
  regenerateDescription = false,
): Promise<{ ai_tags: Record<string, unknown>; ai_description: string }> {
  const { data } = await axiosInstance.post<{
    ai_tags: Record<string, unknown>
    ai_description: string
  }>(`/api/v1/artworks/${id}/ai-enhance/`, { regenerate_description: regenerateDescription })
  return data
}

export async function getArtworkCategories(): Promise<ArtworkCategoryItem[]> {
  const { data } = await axiosInstance.get<
    ArtworkCategoryItem[] | { results?: ArtworkCategoryItem[] }
  >('/api/v1/artworks/categories/')
  if (Array.isArray(data)) return data
  return data.results ?? []
}
