import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../artworks/domain/artwork_model.dart';
import '../../events/domain/event_model.dart';

class AiService {
  Dio get _dio => ApiClient.instance.dio;

  /// Sends a message to the cultural AI assistant.
  /// [history] is a list of previous turns: `[{'role': 'user'/'assistant', 'text': '...'}]`
  Future<String> chat({
    required String mensaje,
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final res = await _dio.post(ApiConstants.aiChat, data: {
        'message': mensaje,
        'history': history,
      });
      final data = res.data;
      if (data is Map) {
        final r = data['reply']?.toString();
        if (r != null && r.isNotEmpty) return r;
      }
      throw const FormatException('Respuesta inválida del servidor.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const FormatException(
            'El asistente IA no está disponible en este momento.');
      }
      rethrow;
    }
  }

  /// Returns artworks sorted by views (most-viewed first) as recommendations.
  /// Uses the real artworks catalog — the AI recommendations endpoint does not exist.
  Future<List<ArtworkModel>> getArtworkRecommendations() async {
    try {
      final res = await _dio.get(
        ApiConstants.artworks,
        queryParameters: {'page_size': 10, 'ordering': '-views_count'},
      );
      final data = res.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => ArtworkModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data is Map && data['results'] is List) {
        return (data['results'] as List)
            .whereType<Map>()
            .map((e) => ArtworkModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const <ArtworkModel>[];
    } catch (_) {
      return const <ArtworkModel>[];
    }
  }

  /// Returns upcoming events as recommendations.
  /// Uses the real events catalog — the AI event-recommendations endpoint does not exist.
  Future<List<EventModel>> getEventRecommendations() async {
    try {
      final res = await _dio.get(ApiConstants.events);
      final data = res.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data is Map && data['results'] is List) {
        return (data['results'] as List)
            .whereType<Map>()
            .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const <EventModel>[];
    } catch (_) {
      return const <EventModel>[];
    }
  }

  /// Computes artist statistics from real API data (artworks + sales).
  /// The AI artist-stats endpoint does not exist in the backend.
  /// [artistSlug] is the artist's profile slug used to filter artworks.
  Future<Map<String, dynamic>> getArtistStats({String? artistSlug}) async {
    try {
      // Paginate all artworks and filter client-side by artist slug
      final myWorks = <ArtworkModel>[];
      if (artistSlug != null && artistSlug.isNotEmpty) {
        String? nextUrl = '${ApiConstants.artworks}?page_size=100';
        while (nextUrl != null) {
          final response = await _dio.get(nextUrl);
          final data = response.data;
          if (data is Map) {
            final raw = (data['results'] as List? ?? []);
            myWorks.addAll(
              raw
                  .whereType<Map>()
                  .map((e) => ArtworkModel.fromJson(
                      Map<String, dynamic>.from(e)))
                  .where((a) => a.artistaSlug == artistSlug),
            );
            nextUrl = data['next'] as String?;
          } else if (data is List) {
            myWorks.addAll(
              data
                  .whereType<Map>()
                  .map((e) => ArtworkModel.fromJson(
                      Map<String, dynamic>.from(e)))
                  .where((a) => a.artistaSlug == artistSlug),
            );
            nextUrl = null;
          } else {
            nextUrl = null;
          }
        }
      }

      // Compute total views from artworks (views_count field)
      final visitasTotal =
          myWorks.fold<int>(0, (sum, a) => sum + a.cantidadFavoritos);

      // Get income from sales history for the current month
      double ingresosMes = 0;
      try {
        final salesRes = await _dio.get(ApiConstants.salesHistory);
        final salesData = salesRes.data;
        final sales = salesData is List
            ? salesData
            : (salesData is Map
                ? (salesData['results'] as List? ?? [])
                : <dynamic>[]);
        final now = DateTime.now();
        for (final sale in sales) {
          if (sale is! Map) continue;
          final dateStr = sale['created_at']?.toString() ?? '';
          final date = DateTime.tryParse(dateStr);
          if (date == null) continue;
          if (date.year == now.year && date.month == now.month) {
            ingresosMes +=
                double.tryParse(sale['total_amount']?.toString() ?? '') ?? 0;
          }
        }
      } catch (_) {}

      // Top artworks sorted by views_count
      myWorks.sort(
          (a, b) => b.cantidadFavoritos.compareTo(a.cantidadFavoritos));
      final topWorks = myWorks.take(5).map((a) => {
            'id': a.id,
            'title': a.titulo,
            'image_url':
                a.imagenes.isNotEmpty ? a.imagenes.first : null,
            'views': a.cantidadFavoritos,
          }).toList();

      return {
        'visitas_mes': 0, // per-month breakdown not available from API
        'visitas_total': visitasTotal,
        'nuevos_seguidores': 0, // followers endpoint not available
        'ingresos_mes': ingresosMes,
        'obras_mas_vistas': topWorks,
      };
    } catch (_) {
      return const <String, dynamic>{};
    }
  }
}
