export const ROUTES = {
  HOME: '/',
  LOGIN: '/login',
  REGISTER: '/register',
  FORGOT_PASSWORD: '/forgot-password',
  RESET_PASSWORD: '/reset-password',
  ARTISTS: '/artists',
  ARTIST_DETAIL: (slug: string) => `/artists/${slug}`,
  ARTWORKS: '/artworks',
  ARTWORK_DETAIL: (id: number) => `/artworks/${id}`,
  MARKETPLACE: '/marketplace',
  AUCTIONS: '/auctions',
  AUCTION_DETAIL: (id: number) => `/auctions/${id}`,
  EVENTS: '/events',
  EVENT_DETAIL: (id: number) => `/events/${id}`,
  CHECKOUT: '/checkout',
  ORDERS: '/orders',
  NOTIFICATIONS: '/notifications',
  PROFILE: '/profile',
  PAYMENT_SUCCESS: '/payment/success',
  PAYMENT_PENDING: '/payment/pending',
  PAYMENT_DECLINED: '/payment/declined',
  DASHBOARD: {
    PROFILE: '/dashboard/profile',
    ARTWORKS: '/dashboard/artworks',
    ARTWORKS_NEW: '/dashboard/artworks/new',
    ARTWORK_EDIT: (id: number) => `/dashboard/artworks/${id}/edit`,
    SALES: '/dashboard/sales',
    ANALYTICS: '/dashboard/analytics',
  },
  ADMIN: {
    DASHBOARD: '/admin/dashboard',
    USERS: '/admin/users',
    ARTWORKS: '/admin/artworks',
    EVENTS: '/admin/events',
    TRANSACTIONS: '/admin/transactions',
  },
} as const

export const ARTWORK_CATEGORIES = [
  { value: 'PINTURA', label: 'Pintura' },
  { value: 'ESCULTURA', label: 'Escultura' },
  { value: 'FOTOGRAFIA', label: 'Fotografía' },
  { value: 'ARTESANIA', label: 'Artesanía' },
  { value: 'TEXTIL', label: 'Textil' },
  { value: 'CERAMICA', label: 'Cerámica' },
  { value: 'GRABADO', label: 'Grabado' },
  { value: 'DIGITAL', label: 'Arte Digital' },
  { value: 'OTRO', label: 'Otro' },
] as const

export const EVENT_TYPES = [
  { value: 'CONCIERTO', label: 'Concierto' },
  { value: 'EXPOSICION', label: 'Exposición' },
  { value: 'TALLER', label: 'Taller' },
  { value: 'CONVOCATORIA', label: 'Convocatoria' },
  { value: 'FESTIVAL', label: 'Festival' },
] as const

export const USER_ROLES = {
  ARTIST: 'artist',
  BUYER: 'buyer',
  CULTURAL_MANAGER: 'cultural_manager',
  ADMIN: 'admin',
} as const

export const ORDER_STATUS_LABELS: Record<string, { label: string; color: string }> = {
  PENDING: { label: 'Pendiente', color: 'bg-yellow-100 text-yellow-800' },
  PAID: { label: 'Pagado', color: 'bg-green-100 text-green-800' },
  SHIPPED: { label: 'Enviado', color: 'bg-blue-100 text-blue-800' },
  DELIVERED: { label: 'Entregado', color: 'bg-accent/10 text-accent' },
  CANCELLED: { label: 'Cancelado', color: 'bg-red-100 text-red-800' },
}

export const AUCTION_STATUS_LABELS: Record<string, string> = {
  UPCOMING: 'Próxima',
  ACTIVE: 'En curso',
  CLOSED: 'Finalizada',
}
