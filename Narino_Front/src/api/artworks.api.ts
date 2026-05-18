import axiosInstance from './axiosInstance'
import type { Artwork } from '@/types/auth'

export interface ArtworkCategoryItem {
  id: number
  name: string
  slug?: string
  description?: string
}

export interface GetArtworksParams {
  category?: string
  search?: string
  page?: number
  page_size?: number
}

export async function getArtworks(params?: GetArtworksParams) {
  const { data } = await axiosInstance.get<Artwork[]>('/api/v1/artworks/', { params })
  return data
}

export async function getArtworkById(id: string | number) {
  const { data } = await axiosInstance.get<Artwork>(`/api/v1/artworks/${id}/`)
  return data
}

export async function getArtworkCategories() {
  const { data } = await axiosInstance.get<ArtworkCategoryItem[]>('/api/v1/artworks/categories/')
  return data
}

export async function getArtworkCategoryById(id: string | number) {
  const { data } = await axiosInstance.get<ArtworkCategoryItem>(`/api/v1/artworks/categories/${id}/`)
  return data
}
