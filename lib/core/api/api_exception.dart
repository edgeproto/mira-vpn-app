import 'package:dio/dio.dart';

/// Typed failure from the HTTP API (after [ErrorInterceptor]).
class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.rawBody,
  });

  final int statusCode;
  final String message;
  final Object? rawBody;

  factory ApiException.fromResponse(Response<dynamic> res) {
    return ApiException(
      statusCode: res.statusCode ?? 0,
      message: _messageFrom(res),
      rawBody: res.data,
    );
  }

  /// When [DioException.error] was replaced by [ApiException].
  static ApiException? fromDio(DioException e) {
    final err = e.error;
    if (err is ApiException) return err;
    final res = e.response;
    if (res != null) {
      return ApiException.fromResponse(res);
    }
    return null;
  }

  static String _messageFrom(Response<dynamic> res) {
    final data = res.data;
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return res.statusMessage?.isNotEmpty == true
        ? res.statusMessage!
        : 'HTTP ${res.statusCode}';
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
