// ─── Roles ───────────────────────────────────────────────────────────────────
export type UserRole = 'artist' | 'buyer' | 'cultural_manager' | 'admin'
export type Role = UserRole
export type BackendRole = 'ARTISTA' | 'COMPRADOR' | 'GESTOR_CULTURAL' | 'ADMINISTRADOR'

const frontendToBackendRole: Record<UserRole, BackendRole> = {
  artist: 'ARTISTA',
  buyer: 'COMPRADOR',
  cultural_manager: 'GESTOR_CULTURAL',
  admin: 'ADMINISTRADOR',
}

const backendToFrontendRole: Record<BackendRole, UserRole> = {
  ARTISTA: 'artist',
  COMPRADOR: 'buyer',
  GESTOR_CULTURAL: 'cultural_manager',
  ADMINISTRADOR: 'admin',
}

export const mapRoleToBackendRole = (role: UserRole): BackendRole =>
  frontendToBackendRole[role]

export const normalizeUserRole = (role: string): UserRole => {
  if (role in backendToFrontendRole) return backendToFrontendRole[role as BackendRole]
  if (role in frontendToBackendRole) return role as UserRole
  return 'buyer'
}

export const normalizeUser = <T extends { role: string }>(
  user: T,
): Omit<T, 'role'> & { role: UserRole } => ({
  ...user,
  role: normalizeUserRole(user.role),
})

// ─── User ─────────────────────────────────────────────────────────────────────
// Matches backend apps.users.models.User exactly.
export interface User {
  id: string            // UUID — backend uses UUIDField
  email: string
  first_name: string
  last_name: string
  role: UserRole
  avatar_url?: string   // URLField in backend (not "avatar")
  phone?: string
  is_verified: boolean
}

// ─── Auth ─────────────────────────────────────────────────────────────────────
export interface AuthTokens {
  access: string
  refresh: string
}

export interface LoginCredentials {
  email: string
  password: string
}

export interface RegisterData {
  email: string
  password: string
  first_name: string
  last_name: string
  role: string          // backend key (ARTISTA, COMPRADOR, etc.)
  phone?: string
  avatar_url?: string
}

// ─── Artist ───────────────────────────────────────────────────────────────────
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

// ─── Artwork ──────────────────────────────────────────────────────────────────
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

// ─── Auction ──────────────────────────────────────────────────────────────────
// Matches backend apps.auctions.models.Auction exactly.
export type AuctionStatus = 'ACTIVA' | 'CERRADA' | 'CANCELADA'

export interface Auction {
  id: string
  artwork: string                         // Artwork UUID FK
  seller: string                          // User UUID FK
  base_price: string                      // DecimalField → string
  current_price: string
  highest_bidder: string | null           // User UUID FK
  status: AuctionStatus
  starts_at: string
  ends_at: string
  winner: string | null                   // User UUID FK
  created_at: string
  updated_at: string
}

export interface Bid {
  id: string
  auction: string                         // Auction UUID FK
  bidder: string                          // User UUID FK
  amount: string                          // DecimalField → string
  created_at: string
}

// ─── Marketplace ──────────────────────────────────────────────────────────────
// Matches backend apps.marketplace.models.Order/OrderItem exactly.
export type OrderStatus = 'PENDIENTE' | 'PAGADO' | 'CANCELADO' | 'REEMBOLSADO'
export type OrderType = 'COMPRA_DIRECTA' | 'SUBASTA'

export interface OrderItem {
  id: string
  artwork: string                         // Artwork UUID FK
  price: string                           // DecimalField → string
  // No quantity — backend enforces one unit per artwork in an order
}

export interface Order {
  id: string
  buyer: string                           // User UUID FK
  total_amount: string                    // DecimalField → string
  status: OrderStatus
  order_type: OrderType
  items: OrderItem[]
  created_at: string
  updated_at: string
}

// ─── Events ───────────────────────────────────────────────────────────────────
// Matches backend apps.events.models.Event exactly.
export type EventType =
  | 'CONCIERTO'
  | 'EXPOSICION'
  | 'TALLER'
  | 'FERIA'
  | 'ESPECTACULO'
  | 'OTRO'

export interface CulturalEvent {
  id: string
  title: string
  description: string
  event_type: EventType
  start_date: string                      // ISO datetime
  end_date: string                        // ISO datetime
  location: string
  latitude?: number
  longitude?: number
  image_url?: string
  is_published: boolean
  organizer: {
    id: string
    email: string
    first_name: string
    last_name: string
  }
  created_at: string
  updated_at: string
}

// ─── Notifications ────────────────────────────────────────────────────────────
// Note: backend NotificationLog is admin-only. This type is UI-only
// until a dedicated user notification endpoint is built on the backend.
export type NotificationType =
  | 'NEW_ARTWORK'
  | 'AUCTION_RESULT'
  | 'PAYMENT'
  | 'NEW_FOLLOWER'
  | 'NEW_EVENT'

export interface Notification {
  id: number
  type: NotificationType
  title: string
  message: string
  is_read: boolean
  created_at: string
  action_url?: string
}

// ─── Pagination ───────────────────────────────────────────────────────────────
export interface PaginatedResponse<T> {
  count: number
  next: string | null
  previous: string | null
  results: T[]
}

// ─── Admin ────────────────────────────────────────────────────────────────────
export interface DashboardMetrics {
  total_users: number
  total_artists: number
  total_artworks: number
  total_sales: number
  active_auctions: number
  monthly_revenue: number
  sales_by_month: Array<{ month: string; total: number }>
  artworks_by_category: Array<{ category: string; count: number }>
}

// ─── Payments ─────────────────────────────────────────────────────────────────
export type TransactionStatus = 'PENDIENTE' | 'APROBADO' | 'RECHAZADO' | 'REEMBOLSADO'

export interface Transaction {
  id: string
  order: string
  wompi_transaction_id: string
  amount: string
  currency: string
  status: TransactionStatus
  payment_method: string
  receipt_url: string
  created_at: string
  updated_at: string
}

// ─── Musicians ────────────────────────────────────────────────────────────────
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
