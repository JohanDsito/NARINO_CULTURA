import 'env_constants.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl => EnvConstants.apiBaseUrl;

  static const String login = '/auth/login/';
  static const String register = '/auth/register/';
  static const String refreshToken = '/auth/token/refresh/';
  static const String logout = '/auth/logout/';

  static const String artists = '/artists/';
  static const String artistDetail = '/artists/{id}/';

  static const String artworks = '/artworks/';
  static const String artworkDetail = '/artworks/{id}/';

  static const String marketplace = '/marketplace/';
  static const String cart = '/marketplace/cart/';
  static const String orders = '/marketplace/orders/';

  static const String auctions = '/auctions/';
  static const String auctionBid = '/auctions/{id}/bid/';

  static const String events = '/events/';

  static const String profile = '/users/me/';

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  static const String cartItems = '/marketplace/cart/items/';
  static const String favorites = '/marketplace/favorites/';
  static const String checkout = '/marketplace/checkout/';
  static const String salesHistory = '/marketplace/sales/';
  static const String initiatePayment = '/payments/initiate/';

  // Auth Sprint 2
  static const String resendVerification = '/auth/resend-verification/';
  static const String forgotPassword = '/auth/password-reset/';

  // Perfiles / artistas
  static const String myProfile = '/users/me/';
  static const String profileById = '/artists/{id}/';
  static const String artistFollow = '/artists/{id}/follow/';

  // Eventos
  static const String eventDetail = '/events/{id}/';

  // Subastas
  static const String auctionDetail = '/auctions/{id}/';
  static const String auctionCancel = '/auctions/{id}/cancel/';

  // WebSocket (usa ws:// en desarrollo, wss:// en producción automáticamente)
  static String get auctionWsBase => EnvConstants.auctionWsBaseUrl;

  // Auth Sprint 2 pendiente
  static const String changeEmail = '/auth/change-email/';
  static const String activeSessions = '/auth/sessions/';
  static const String sessionDetail = '/auth/sessions/{id}/';
  static const String deleteAccount = '/auth/delete-account/';

  // Inteligencia Artificial
  static const String aiChat = '/ai/chat/';
  static const String aiRecommendations = '/ai/recommendations/';
  static const String aiEventRecommendations = '/ai/event-recommendations/';
  static const String aiArtistStats = '/ai/artist-stats/';

  // Notificaciones (generadas por n8n)
  static const String notifications = '/notifications/';
  static const String notificationRead = '/notifications/{id}/read/';
  static const String notificationsReadAll = '/notifications/read-all/';

  // Preferencias de notificación de eventos (HU-34)
  static const String eventNotificationPreferences =
      '/notifications/event-preferences/';
}
