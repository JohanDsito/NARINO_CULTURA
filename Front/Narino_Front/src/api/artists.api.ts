import axiosInstance from '@/api/axiosInstance'
import type { ArtistProfile, PaginatedResponse } from '@/types/auth'

export interface CreateArtistProfilePayload {
  artistic_name: string
  bio?: string
  trajectory?: string
  discipline?: string
  city?: string
  website_url?: string
  instagram_url?: string
  facebook_url?: string
  tiktok_url?: string
}

export interface GetArtistsParams {
  search?: string
  page?: number
  page_size?: number
}

export async function listArtistProfiles(
  params?: GetArtistsParams,
): Promise<ArtistProfile[]> {
  const { data } = await axiosInstance.get<
    ArtistProfile[] | PaginatedResponse<ArtistProfile>
  >('/api/v1/artists/', { params })
  return Array.isArray(data) ? data : data.results ?? []
}

export async function getArtistBySlug(slug: string): Promise<ArtistProfile> {
  const { data } = await axiosInstance.get<ArtistProfile>(`/api/v1/artists/${slug}/`)
  return data
}

export async function createArtistProfile(
  payload: CreateArtistProfilePayload,
): Promise<ArtistProfile> {
  const { data } = await axiosInstance.post<ArtistProfile>('/api/v1/artists/', payload)
  return data
}

export async function updateArtistProfile(
  slug: string,
  payload: Partial<CreateArtistProfilePayload>,
): Promise<ArtistProfile> {
  const { data } = await axiosInstance.patch<ArtistProfile>(
    `/api/v1/artists/${slug}/`,
    payload,
  )
  return data
}

export async function followArtist(slug: string): Promise<{ detail: string }> {
  const { data } = await axiosInstance.post<{ detail: string }>(
    `/api/v1/artists/${slug}/follow/`,
  )
  return data
}

export interface FollowItem {
  id: string
  slug?: string
  artistic_name?: string
  first_name?: string
  last_name?: string
  avatar_url?: string
}

export async function getArtistFollowers(slug: string): Promise<FollowItem[]> {
  const { data } = await axiosInstance.get<FollowItem[] | { results?: FollowItem[] }>(
    `/api/v1/artists/${slug}/followers/`,
  )
  return Array.isArray(data) ? data : data.results ?? []
}

export async function getMyFollowing(): Promise<FollowItem[]> {
  const { data } = await axiosInstance.get<FollowItem[] | { results?: FollowItem[] }>(
    '/api/v1/artists/following/',
  )
  return Array.isArray(data) ? data : data.results ?? []
}
