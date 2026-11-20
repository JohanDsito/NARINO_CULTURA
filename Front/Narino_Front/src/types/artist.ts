// Matches backend apps.artists.models.ArtistProfile exactly.
export interface ArtistProfile {
  id: string
  user_id: string
  slug: string
  artistic_name: string
  bio: string
  trajectory: string
  discipline: string | null
  city: string
  website_url: string
  instagram_url: string
  facebook_url: string
  tiktok_url: string
  followers_count: number
  is_public: boolean
  profile_image_url?: string
  created_at: string
  updated_at: string
  is_following?: boolean // annotated by backend or derived from follow endpoint
}
