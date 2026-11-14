// Matches backend apps.musicians.models.MusicianProfile exactly.
export type AggregationType = 'SOLISTA' | 'BANDA' | 'DJ' | 'COLECTIVO' | 'DUO' | 'TRIO'

export interface MusicGenre {
  id: number
  name: string
  slug: string
  description: string
  icon: string
}

export interface MusicianProfile {
  id: string
  user_id: string
  artistic_name: string
  slug: string
  aggregation_type: AggregationType
  city: string
  region: string
  bio: string
  founding_year?: number
  genres: MusicGenre[]
  spotify_url: string
  youtube_url: string
  soundcloud_url: string
  apple_music_url: string
  instagram_handle: string
  tiktok_handle: string
  website_url: string
  contact_email: string
  booking_email: string
  phone: string
  profile_image_url: string
  is_verified: boolean
  is_active: boolean
  followers_count: number
  popularity_score: number
  created_at: string
  updated_at: string
}

export interface MusicalWork {
  id: string
  musician: string                        // MusicianProfile UUID FK
  title: string
  work_type: 'VIDEO' | 'LIVE' | 'STUDIO' | 'COVER' | 'PODCAST'
  youtube_url: string
  soundcloud_embed: string
  spotify_track_url: string
  audio_file: string
  thumbnail: string
  description: string
  release_date?: string
  views_count: number
  duration_seconds?: number
  is_featured: boolean
  created_at: string
  updated_at: string
}

export interface MusicianReview {
  id: string
  musician: string
  reviewer: string
  rating: number
  comment: string
  created_at: string
  updated_at: string
}

export interface MusicDiscoveryResult {
  query: string
  filters_applied: Record<string, unknown>
  count: number
  results: MusicianProfile[]
}
