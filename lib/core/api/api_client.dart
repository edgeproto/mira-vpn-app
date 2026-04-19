import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Shared [Dio] instance with base URL, auth header, and error mapping.
class ApiClient {
  ApiClient({
    required Future<String?> Function() getToken,
    Dio? dio,
  }) : dio = dio ?? _createDio(getToken);

  final Dio dio;

  static Dio _createDio(Future<String?> Function() getToken) {
    final d = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {Headers.contentTypeHeader: Headers.jsonContentType},
      ),
    );
    d.interceptors.addAll([
      AuthInterceptor(getToken: getToken),
      ErrorInterceptor(),
    ]);
    return d;
  }
}
