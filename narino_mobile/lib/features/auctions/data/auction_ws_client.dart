import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/storage_utils.dart';

class AuctionWsClient {
  WebSocketChannel? _channel;

  Stream<dynamic>? get stream => _channel?.stream;

  Future<void> connect(int auctionId) async {
    await close();

    final token = await StorageUtils.getAccessToken();
    final base = Uri.parse('${ApiConstants.auctionWsBase}$auctionId/');

    final wsUri = base.replace(
      queryParameters: {
        if (token != null && token.isNotEmpty) 'token': token,
      },
    );

    _channel = IOWebSocketChannel.connect(wsUri);
  }

  Map<String, dynamic>? tryDecodeMessage(dynamic message) {
    try {
      if (message is String) {
        final decoded = jsonDecode(message);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      }
    } catch (_) {}
    return null;
  }

  Future<void> close() async {
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }
}
