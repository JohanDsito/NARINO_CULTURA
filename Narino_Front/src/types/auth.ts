// ─── Auth ────────────────────────────────────────────
export type UserRole = 'artist' | 'buyer' | 'cultural_manager' | 'admin'
export type Role = UserRole

export const mapRoleToBackendRole = (role: UserRole): string => {
  const roleMap: Record<UserRole, string> = {
    artist: 'ARTISTA',
    buyer: 'COMPRADOR',
    cultural_manager: 'GESTOR_CULTURAL',
    admin: 'ADMINISTRADOR',
  }
  return roleMap[role]
}

export interface User {
  id: number
  email: string
  first_name: string
  last_name: string
  role: UserRole
  avatar?: string
  artistic_name?: string
  category?: string
  city?: string
  bio?: string
  followers_count?: number
  following_count?: number
  is_verified?: boolean
  social_links?: { instagram?: string; facebook?: string; twitter?: string }
}

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
  role: UserRole
  artistic_name?: string
  category?: string
  city?: string
}

// ─── Artist ─────────────────────────────────────────
export interface Artist {
  id: number
  slug: string
  artistic_name: string
  full_name: string
  category: ArtworkCategory
  city: string
  bio: string
  avatar: string
  banner?: string
  followers_count: number
  artworks_count: number
  is_following?: boolean
  social_links?: { instagram?: string; facebook?: string; twitter?: string }
  trajectory?: string
}

// ─── Artwork ─────────────────────────────────────────
export type ArtworkStatus = 'DISPONIBLE' | 'EN_SUBASTA' | 'VENDIDO' | 'PENDIENTE'
export type ArtworkCategory =
  | 'PINTURA' | 'ESCULTURA' | 'FOTOGRAFIA' | 'ARTESANIA'
  | 'TEXTIL' | 'CERAMICA' | 'GRABADO' | 'DIGITAL' | 'OTRO'

export interface Artwork {
  id: number
  title: string
  slug: string
  description: string
  price: number
  category: ArtworkCategory
  technique: string
  dimensions?: string
  year?: number
  status: ArtworkStatus
  images: ArtworkImage[]
  artist: Artist
  views_count: number
  likes_count: number
  is_liked?: boolean
  created_at: string
  updated_at: string
}

export interface ArtworkImage {
  id: number
  url: string
  is_primary: boolean
  order: number
}

// ─── Auction ─────────────────────────────────────────
export type AuctionStatus = 'UPCOMING' | 'ACTIVE' | 'CLOSED'

export interface Auction {
  id: number
  artwork: Artwork
  starting_price: number
  current_price: number
  min_increment: number
  status: AuctionStatus
  starts_at: string
  ends_at: string
  bids_count: number
  winner?: User
}

export interface Bid {
  id: number
  auction: number
  bidder: User
  amount: number
  created_at: string
}

// ─── Marketplace ─────────────────────────────────────
export type OrderStatus =
  | 'PENDING' | 'PAID' | 'SHIPPED' | 'DELIVERED' | 'CANCELLED'

export interface Order {
  id: number
  reference: string
  items: OrderItem[]
  total: number
  status: OrderStatus
  shipping_address: string
  created_at: string
  payment_method?: string
  transaction_id?: string
}

export interface OrderItem {
  id: number
  artwork: Artwork
  price: number
  quantity: number
}

// ─── Event ───────────────────────────────────────────
export type EventType =
  | 'CONCIERTO' | 'EXPOSICION' | 'TALLER' | 'CONVOCATORIA' | 'FESTIVAL'

export interface CulturalEvent {
  id: number
  title: string
  slug: string
  description: string
  type: EventType
  image: string
  date: string
  time: string
  location: string
  organizer: string
  is_carnival?: boolean
  is_interested?: boolean
  interested_count: number
}

// ─── Notification ────────────────────────────────────
export type NotificationType =
  | 'NEW_ARTWORK' | 'AUCTION_RESULT' | 'PAYMENT' | 'NEW_FOLLOWER' | 'NEW_EVENT'

export interface Notification {
  id: number
  type: NotificationType
  title: string
  message: string
  is_read: boolean
  created_at: string
  action_url?: string
}

// ─── Pagination ──────────────────────────────────────
export interface PaginatedResponse<T> {
  count: number
  next: string | null
  previous: string | null
  results: T[]
}

// ─── Admin ───────────────────────────────────────────
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