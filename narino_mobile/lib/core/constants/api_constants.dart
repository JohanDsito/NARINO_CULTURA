import 'env_constants.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl => EnvConstants.apiBaseUrl;

  // Auth
  static const String login = '/api/v1/auth/login/';
  static const String register = '/api/v1/auth/register/';
  static const String refreshToken = '/api/v1/auth/token/refresh/';
  static const String logout = '/api/v1/auth/logout/';
  static const String resendVerification = '/api/v1/auth/resend-verification/';
  static const String forgotPassword = '/api/v1/auth/password-reset/';
  static const String changeEmail = '/api/v1/auth/change-email/';
  static const String activeSessions = '/api/v1/auth/sessions/';
  static const String sessionDetail = '/api/v1/auth/sessions/{id}/';
  static const String deleteAccount = '/api/v1/auth/delete-account/';

  // Perfil de usuario
  static const String profile = '/api/v1/users/me/';
  static const String myProfile = '/api/v1/users/me/';
  static const String myFollowing = '/api/v1/users/me/following/';

  // Artistas
  static const String artists = '/api/v1/artists/';
  static const String artistMe = '/api/v1/artists/me/';
  static const String artistDetail = '/api/v1/artists/{id}/';
  static const String profileById = '/api/v1/artists/{id}/';
  static const String artistFollow = '/api/v1/artists/{id}/follow/';
  static const String artistPortfolio = '/api/v1/artists/{id}/portfolio/';
  static const String artistPortfolioItem =
      '/api/v1/artists/{id}/portfolio/{item_id}/';

  // Obras
  static const String artworks = '/api/v1/artworks/';
  static const String artworkDetail = '/api/v1/artworks/{id}/';
  static const String artworkCategories = '/api/v1/artworks/categories/';

  // Marketplace
  static const String marketplace = '/api/v1/marketplace/';
  static const String cart = '/api/v1/marketplace/cart/';
  static const String cartItems = '/api/v1/marketplace/cart/items/';
  static const String orders = '/api/v1/marketplace/orders/';
  static const String orderDetail = '/api/v1/marketplace/orders/{id}/';
  static const String favorites = '/api/v1/marketplace/favorites/';
  static const String checkout = '/api/v1/marketplace/checkout/';
  static const String salesHistory = '/api/v1/marketplace/sales/';

  // Pagos
  static const String initiatePayment = '/api/v1/payments/initiate/';

  // Subastas
  static const String auctions = '/api/v1/auctions/';
  static const String auctionBid = '/api/v1/auctions/{id}/bid/';
  static const String auctionDetail = '/api/v1/auctions/{id}/';
  static const String auctionCancel = '/api/v1/auctions/{id}/cancel/';

  // Eventos
  static const String events = '/api/v1/events/';
  static const String eventDetail = '/api/v1/events/{id}/';
  static const String eventRegister = '/api/v1/events/{id}/register/';

  // Músicos
  static const String musicians = '/api/v1/musicians/';
  static const String musicianMe = '/api/v1/musicians/me/';
  static const String musicianGenres = '/api/v1/musicians/genres/';
  static const String musicianDetail = '/api/v1/musicians/{slug}/';
  static const String musicianFollow = '/api/v1/musicians/{slug}/follow/';
  static const String musicianWorks = '/api/v1/musicians/{slug}/works/';
  static const String musicianAddWork = '/api/v1/musicians/{slug}/works/add/';
  static const String musicianReviews = '/api/v1/musicians/{slug}/reviews/';

  // Descubrimiento musical
  static const String musicDiscoveryRecommendations =
      '/api/v1/music-discovery/recommendations/';

  // Inteligencia Artificial
  static const String aiChat = '/api/v1/chat/';
  static const String aiRecommendations = '/api/v1/ai/recommendations/';
  static const String aiEventRecommendations =
      '/api/v1/ai/event-recommendations/';
  static const String aiArtistStats = '/api/v1/ai/artist-stats/';

  // Notificaciones
  static const String notifications = '/api/v1/notifications/';
  static const String notificationRead = '/api/v1/notifications/{id}/read/';
  static const String notificationsReadAll =
      '/api/v1/notifications/read-all/';
  static const String eventNotificationPreferences =
      '/api/v1/notifications/event-preferences/';

  // WebSocket
  static String get auctionWsBase => EnvConstants.auctionWsBaseUrl;

  // Timeouts
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}
