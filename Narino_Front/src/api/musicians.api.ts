import axiosInstance from './axiosInstance'
import type {
  MusicianProfile,
  MusicalWork,
  MusicGenre,
  MusicDiscoveryResult,
  MusicianReview,
  PaginatedResponse,
  AggregationType,
} from '@/types/auth'

export interface GetMusiciansParams {
  aggregation_type?: AggregationType
  city?: string
  region?: string
  is_verified?: boolean
  search?: string
  ordering?: string
  page?: number
  page_size?: number
}

export interface CreateMusicianProfilePayload {
  artistic_name: string
  aggregation_type?: AggregationType
  city?: string
  region?: string
  bio?: string
  founding_year?: number
  genre_ids?: number[]
  spotify_url?: string
  youtube_url?: string
  soundcloud_url?: string
  apple_music_url?: string
  instagram_handle?: string
  tiktok_handle?: string
  website_url?: string
  contact_email?: string
  booking_email?: string
  phone?: string
}

export async function listMusicians(
  params?: GetMusiciansParams,
): Promise<PaginatedResponse<MusicianProfile>> {
  const { data } = await axiosInstance.get<
    PaginatedResponse<MusicianProfile> | MusicianProfile[]
  >('/api/v1/musicians/', { params })
  if (Array.isArray(data)) {
    return { count: data.length, next: null, previous: null, results: data }
  }
  return data
}

export async function getMusicianBySlug(slug: string): Promise<MusicianProfile> {
  const { data } = await axiosInstance.get<MusicianProfile>(`/api/v1/musicians/${slug}/`)
  return data
}

export async function getMyMusicianProfile(): Promise<MusicianProfile> {
  const { data } = await axiosInstance.get<MusicianProfile>('/api/v1/musicians/me/')
  return data
}

export async function createMusicianProfile(
  payload: CreateMusicianProfilePayload,
): Promise<MusicianProfile> {
  const { data } = await axiosInstance.post<MusicianProfile>('/api/v1/musicians/', payload)
  return data
}

export async function updateMusicianProfile(
  slug: string,
  payload: Partial<CreateMusicianProfilePayload>,
): Promise<MusicianProfile> {
  const { data } = await axiosInstance.patch<MusicianProfile>(
    `/api/v1/musicians/${slug}/`,
    payload,
  )
  return data
}

export async function followMusician(slug: string): Promise<{ detail: string }> {
  const { data } = await axiosInstance.post<{ detail: string }>(
    `/api/v1/musicians/${slug}/follow/`,
  )
  return data
}

export async function getMusicianWorks(
  slug: string,
  type?: string,
): Promise<MusicalWork[]> {
  const { data } = await axiosInstance.get<MusicalWork[] | PaginatedResponse<MusicalWork>>(
    `/api/v1/musicians/${slug}/works/`,
    { params: type ? { type } : undefined },
  )
  return Array.isArray(data) ? data : data.results ?? []
}

export async function getMusicianReviews(slug: string): Promise<MusicianReview[]> {
  const { data } = await axiosInstance.get<
    MusicianReview[] | PaginatedResponse<MusicianReview>
  >(`/api/v1/musicians/${slug}/reviews/`)
  return Array.isArray(data) ? data : data.results ?? []
}

export async function getMusicGenres(): Promise<MusicGenre[]> {
  const { data } = await axiosInstance.get<MusicGenre[]>('/api/v1/musicians/genres/')
  return data
}

export async function musicDiscovery(query: string): Promise<MusicDiscoveryResult> {
  const { data } = await axiosInstance.post<MusicDiscoveryResult>(
    '/api/v1/music-discovery/recommendations/',
    { query },
  )
  return data
}
