export const ROUTES = {
  home: '/',
  login: '/login',
  register: '/register',
  forgotPassword: '/forgot-password',
  resetPassword: '/reset-password',

  artists: '/artists',
  artistDetail: (slug: string) => `/artists/${slug}`,

  artworks: '/artworks',
  artworkDetail: (id: string) => `/artworks/${id}`,

  marketplace: '/marketplace',
  auctions: '/auctions',
  auctionRoom: (id: string) => `/auctions/${id}`,
  events: '/events',
  eventDetail: (id: string) => `/events/${id}`,

  checkout: '/checkout',
  orders: '/orders',
  notifications: '/notifications',
  profile: '/profile',

  paymentSuccess: '/payment/success',
  paymentPending: '/payment/pending',
  paymentDeclined: '/payment/declined',

  dashboardProfile: '/dashboard/profile',
  dashboardArtworks: '/dashboard/artworks',
  dashboardArtworkNew: '/dashboard/artworks/new',
  dashboardArtworkEdit: (id: string) => `/dashboard/artworks/${id}/edit`,
  dashboardSales: '/dashboard/sales',
  dashboardAnalytics: '/dashboard/analytics',

  adminDashboard: '/admin/dashboard',
  adminUsers: '/admin/users',
  adminArtworks: '/admin/artworks',
  adminEvents: '/admin/events',
  adminTransactions: '/admin/transactions',
} as const

