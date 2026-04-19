import 'package:dio/dio.dart';

import '../api_exception.dart';

/// Maps HTTP error responses to [ApiException] on [DioException.error].
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final res = err.response;
    if (res != null) {
      final api = ApiException.fromResponse(res);
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: res,
          type: err.type,
          error: api,
        ),
      );
      return;
    }
    handler.next(err);
  }
}
