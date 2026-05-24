export const ROUTES = {
  HOME: '/',
  LOGIN: '/login',
  REGISTER: '/register',
  FORGOT_PASSWORD: '/forgot-password',
  RESET_PASSWORD: '/reset-password',
  ARTISTS: '/artists',
  ARTIST_DETAIL: (slug: string) => `/artists/${slug}`,
  ARTWORKS: '/artworks',
  ARTWORK_DETAIL: (id: string | number) => `/artworks/${id}`,
  MARKETPLACE: '/marketplace',
  AUCTIONS: '/auctions',
  AUCTION_DETAIL: (id: string | number) => `/auctions/${id}`,
  EVENTS: '/events',
  EVENT_DETAIL: (id: string | number) => `/events/${id}`,
  MUSICIANS: '/musicians',
  MUSICIAN_DETAIL: (slug: string) => `/musicians/${slug}`,
  MUSIC_DISCOVERY: '/music-discovery',
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
    ARTWORK_EDIT: (id: string | number) => `/dashboard/artworks/${id}/edit`,
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

export const EVENT_TYPES = [
  { value: 'CONCIERTO', label: 'Concierto' },
  { value: 'EXPOSICION', label: 'Exposición' },
  { value: 'TALLER', label: 'Taller' },
  { value: 'FERIA', label: 'Feria' },
  { value: 'ESPECTACULO', label: 'Espectáculo' },
  { value: 'OTRO', label: 'Otro' },
] as const

export const USER_ROLES = {
  ARTIST: 'artist',
  BUYER: 'buyer',
  CULTURAL_MANAGER: 'cultural_manager',
  ADMIN: 'admin',
} as const

export const ORDER_STATUS_LABELS: Record<string, { label: string; color: string }> = {
  PENDIENTE: { label: 'Pendiente', color: 'bg-yellow-100 text-yellow-800' },
  PAGADO: { label: 'Pagado', color: 'bg-green-100 text-green-800' },
  CANCELADO: { label: 'Cancelado', color: 'bg-red-100 text-red-800' },
  REEMBOLSADO: { label: 'Reembolsado', color: 'bg-blue-100 text-blue-800' },
}

export const AUCTION_STATUS_LABELS: Record<string, string> = {
  ACTIVA: 'En curso',
  CERRADA: 'Finalizada',
  CANCELADA: 'Cancelada',
}

export const AGGREGATION_TYPE_LABELS: Record<string, string> = {
  SOLISTA: 'Solista',
  BANDA: 'Banda',
  DJ: 'DJ',
  COLECTIVO: 'Colectivo',
  DUO: 'Dúo',
  TRIO: 'Trío',
}

export const MUSICAL_WORK_TYPE_LABELS: Record<string, string> = {
  VIDEO: 'Video',
  LIVE: 'En vivo',
  STUDIO: 'Estudio',
  COVER: 'Cover',
  PODCAST: 'Podcast',
}
