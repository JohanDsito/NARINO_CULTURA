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

  static const String cartItem = '/marketplace/cart/{id}/';
  static const String favorites = '/marketplace/favorites/';
  static const String favoriteItem = '/marketplace/favorites/{id}/';
  static const String orderDetail = '/marketplace/orders/{id}/';
  static const String orderCheckout = '/marketplace/orders/{id}/checkout/';
  static const String purchaseHistory = '/marketplace/purchases/';
  static const String salesHistory = '/marketplace/sales/';
  static const String initiatePayment = '/payments/initiate/';
  static const String paymentStatus = '/payments/{id}/status/';

  // Auth Sprint 2
  static const String resendVerification = '/auth/resend-verification/';
  static const String forgotPassword = '/auth/forgot-password/';

  // Perfiles
  static const String myProfile = '/profiles/me/';
  static const String profileById = '/profiles/{id}/';
  static const String portfolioItems = '/profiles/{id}/portfolio/';
  static const String portfolioItem = '/profiles/{id}/portfolio/{item_id}/';
  static const String followArtist = '/profiles/{id}/follow/';
  static const String unfollowArtist = '/profiles/{id}/unfollow/';
  static const String myFollowing = '/profiles/following/';

  // Eventos
  static const String eventDetail = '/events/{id}/';

  // Subastas
  static const String auctionDetail = '/auctions/{id}/';
  static const String auctionCancel = '/auctions/{id}/cancel/';

  // WebSocket (usa ws:// o wss:// según el entorno)
  static const String auctionWsBase = 'ws://10.0.2.2:8000/ws/auctions/';
  // En producción cambiar a: wss://tu-dominio.com/ws/auctions/

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
