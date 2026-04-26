class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

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
}
