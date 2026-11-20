// Matches backend apps.artworks.models.Artwork exactly.
export type ArtworkStatus = 'DISPONIBLE' | 'EN_SUBASTA' | 'VENDIDA' | 'INACTIVA'

export interface Category {
  id: number
  name: string
  slug: string
  description?: string
}

export interface ArtworkImage {
  id: string
  image_url: string
  order: number
  // No is_primary — derive primary image as the one with order === 0
}

export interface Artwork {
  id: string                              // UUID
  title: string
  description: string
  price: string                           // DecimalField serializes as string in DRF
  category: number | null                 // FK id (write + read)
  category_detail?: Category | null       // nested object (read-only)
  technique: string
  dimensions: string
  material: string
  status: ArtworkStatus
  main_image_url: string
  ai_tags: Record<string, unknown>
  ai_description: string
  views_count: number
  images: ArtworkImage[]
  artist: string                          // ArtistProfile UUID FK
  artist_slug?: string
  created_at: string
  updated_at: string
}
