import axiosInstance from '@/api/axiosInstance'

export interface CreateArtistProfilePayload {
  artistic_name: string
  discipline?: string
  city?: string
  bio?: string
}

export interface ArtistProfile {
  id: string
  user_id: string
  slug: string
  artistic_name: string
  bio: string
  trajectory: string
  discipline: string
  city: string
  website_url: string
  instagram_url: string
  facebook_url: string
  tiktok_url: string
  followers_count: number
  is_public: boolean
  created_at: string
  updated_at: string
}

export async function createArtistProfile(payload: CreateArtistProfilePayload) {
  const { data } = await axiosInstance.post<ArtistProfile>('/api/v1/artists/', payload)
  return data
}

export async function listArtistProfiles() {
  const { data } = await axiosInstance.get<ArtistProfile[] | { results: ArtistProfile[] }>('/api/v1/artists/')
  return Array.isArray(data) ? data : data.results || []
}

export async function updateArtistProfile(slug: string, payload: Partial<CreateArtistProfilePayload>) {
  const { data } = await axiosInstance.patch<ArtistProfile>(`/api/v1/artists/${slug}/`, payload)
  return data
}
