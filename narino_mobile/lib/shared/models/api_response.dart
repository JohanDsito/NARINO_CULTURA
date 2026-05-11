import 'package:equatable/equatable.dart';

/// Modelo genérico para estandarizar respuestas del backend cuando aplica.
class ApiResponse<T> extends Equatable {
  const ApiResponse({
    required this.data,
    this.message,
    this.errors,
  });

  final T? data;
  final String? message;
  final Object? errors;

  static ApiResponse<T> fromJson<T>(
    Map<String, dynamic> json, {
    T Function(Object? raw)? dataParser,
  }) {
    final rawData = json['data'];
    return ApiResponse<T>(
      data: dataParser == null ? rawData as T? : dataParser(rawData),
      message: json['message'] as String?,
      errors: json['errors'],
    );
  }

  @override
  List<Object?> get props => [data, message, errors];
}
