import axiosInstance from './axiosInstance'
import type { Artwork } from '@/types/auth'

export interface ArtworkCategoryItem {
  id: number
  name: string
  slug?: string
  description?: string
}

interface ArtworkCategoryListResponse {
  results?: ArtworkCategoryItem[]
}

interface ArtworkListResponse {
  results?: Artwork[]
}

export interface GetArtworksParams {
  category?: string
  artist?: string | number
  search?: string
  page?: number
  page_size?: number
}

export interface CreateArtworkPayload {
  title: string
  description: string
  category: number
  price?: number
  technique?: string
  dimensions?: string
  year?: number
  image_url?: string
  release_date?: string
  composer?: string
  genre?: string
  demo?: File
}

export async function getArtworks(params?: GetArtworksParams) {
  const { data } = await axiosInstance.get<Artwork[] | ArtworkListResponse>('/api/v1/artworks/', { params })
  return Array.isArray(data) ? data : data.results || []
}

export async function createArtwork(payload: CreateArtworkPayload) {
  if (payload.demo) {
    const formData = new FormData()

    formData.append('title', payload.title)
    formData.append('description', payload.description)
    formData.append('category', String(payload.category))

    if (payload.price !== undefined) formData.append('price', String(payload.price))
    if (payload.technique) formData.append('technique', payload.technique)
    if (payload.dimensions) formData.append('dimensions', payload.dimensions)
    if (payload.year !== undefined) formData.append('year', String(payload.year))
    if (payload.image_url) formData.append('image_url', payload.image_url)
    if (payload.release_date) formData.append('release_date', payload.release_date)
    if (payload.composer) formData.append('composer', payload.composer)
    if (payload.genre) formData.append('genre', payload.genre)
    formData.append('demo', payload.demo)

    const { data } = await axiosInstance.post<Artwork>('/api/v1/artworks/', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
    return data
  }

  const { data } = await axiosInstance.post<Artwork>('/api/v1/artworks/', payload)
  return data
}

export async function getArtworkById(id: string | number) {
  const { data } = await axiosInstance.get<Artwork>(`/api/v1/artworks/${id}/`)
  return data
}

export async function getArtworkCategories() {
  const { data } = await axiosInstance.get<ArtworkCategoryItem[] | ArtworkCategoryListResponse>(
    '/api/v1/artworks/categories/',
  )

  if (Array.isArray(data)) return data

  return data.results ?? []
}

export async function getArtworkCategoryById(id: string | number) {
  const { data } = await axiosInstance.get<ArtworkCategoryItem>(`/api/v1/artworks/categories/${id}/`)
  return data
}
