import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/core/constants/env_constants.dart';

void main() {
  test('sin --dart-define apunta a producción y deriva el WebSocket de subastas', () {
    expect(EnvConstants.apiBaseUrl, 'https://narinocultura-production.up.railway.app');
    expect(EnvConstants.auctionWsBaseUrl, 'wss://narinocultura-production.up.railway.app/ws/auctions/');
  });
}
