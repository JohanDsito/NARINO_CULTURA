class EnvConstants {
  EnvConstants._();

  static const String devBaseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String prodBaseUrl =
      'https://narinocultura-production.up.railway.app/api/v1';

  static const String devWsBase = 'ws://10.0.2.2:8000/ws/auctions/';
  static const String prodWsBase =
      'wss://narinocultura-production.up.railway.app/ws/auctions/';

  static String get apiBaseUrl =>
      const bool.fromEnvironment('dart.vm.product') ? prodBaseUrl : devBaseUrl;

  static String get auctionWsBaseUrl =>
      const bool.fromEnvironment('dart.vm.product') ? prodWsBase : devWsBase;
}

