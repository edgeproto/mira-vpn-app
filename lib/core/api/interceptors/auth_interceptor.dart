import 'package:dio/dio.dart';

/// Injects `Authorization: Bearer <token>` when [getToken] returns non-empty.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.getToken});

  final Future<String?> Function() getToken;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    getToken().then((token) {
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }).catchError((Object e, StackTrace st) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          stackTrace: st,
        ),
      );
    });
  }
}
