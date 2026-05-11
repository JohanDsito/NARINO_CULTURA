import 'dart:io';

import 'package:dio/dio.dart';

import '../domain/profile_model.dart';
import '../domain/portfolio_item_model.dart';
import 'profile_service.dart';

/// Repositorio de perfil: lectura/edición del perfil y manejo de portafolio y seguimientos.
class ProfileRepository {
  ProfileRepository({ProfileService? service})
      : _service = service ?? ProfileService();

  final ProfileService _service;

  Future<ProfileModel?> getMyProfile() async {
    try {
      final data = await _service.getMyProfile();
      return ProfileModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _parseDioError(e);
    }
  }

  Future<ProfileModel> updateMyProfile({
    String? nombreArtistico,
    String? disciplina,
    String? biografia,
    File? foto,
    Map<String, String>? redesSociales,
  }) async {
    try {
      final data = await _service.updateMyProfile(
        nombreArtistico: nombreArtistico,
        disciplina: disciplina,
        biografia: biografia,
        foto: foto,
        redesSociales: redesSociales,
      );
      return ProfileModel.fromJson(data);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<ProfileModel> getProfileById(int id) async {
    try {
      final data = await _service.getProfileById(id);
      return ProfileModel.fromJson(data);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<List<PortfolioItemModel>> getPortfolio(int profileId) async {
    try {
      final data = await _service.getPortfolio(profileId);
      return data
          .whereType<Map>()
          .map((e) => PortfolioItemModel.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v))))
          .toList()
        ..sort((a, b) => a.orden.compareTo(b.orden));
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<PortfolioItemModel> addPortfolioItem({
    required int profileId,
    required File file,
    required String tipo,
    String? titulo,
    String? descripcion,
  }) async {
    try {
      final data = await _service.addPortfolioItem(
        profileId: profileId,
        file: file,
        tipo: tipo,
        titulo: titulo,
        descripcion: descripcion,
      );
      return PortfolioItemModel.fromJson(data);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<PortfolioItemModel> updatePortfolioItemOrder({
    required int profileId,
    required int itemId,
    required int orden,
  }) async {
    try {
      final data = await _service.updatePortfolioItem(
        profileId,
        itemId,
        {'orden': orden},
      );
      return PortfolioItemModel.fromJson(data);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<void> deletePortfolioItem(int profileId, int itemId) async {
    try {
      await _service.deletePortfolioItem(profileId, itemId);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<ProfileModel> followArtist(int profileId) async {
    try {
      final data = await _service.followArtist(profileId);
      return ProfileModel.fromJson(data);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<ProfileModel> unfollowArtist(int profileId) async {
    try {
      final data = await _service.unfollowArtist(profileId);
      return ProfileModel.fromJson(data);
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  Future<List<ProfileModel>> getMyFollowing() async {
    try {
      final data = await _service.getMyFollowing();
      return data
          .whereType<Map>()
          .map((e) =>
              ProfileModel.fromJson(e.map((k, v) => MapEntry(k.toString(), v))))
          .toList();
    } on DioException catch (e) {
      throw _parseDioError(e);
    }
  }

  String _parseDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar al servidor.';
    }

    final code = e.response?.statusCode;
    final body = e.response?.data;

    if (code == 401) return 'Tu sesión expiró. Inicia sesión nuevamente.';
    if (code == 403) return 'No tienes permiso para realizar esta acción.';
    if (code == 404) return 'Recurso no encontrado.';

    final extracted = _extractMessage(body);
    if (extracted != null && extracted.isNotEmpty) return extracted;

    return 'Error inesperado. Intenta de nuevo.';
  }

  String? _extractMessage(Object? data) {
    if (data is Map) {
      final detail = data['detail']?.toString();
      if (detail != null && detail.isNotEmpty) return detail;

      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          final msg = value.first?.toString();
          if (msg != null && msg.isNotEmpty) return msg;
        }
      }
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
