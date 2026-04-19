import 'package:dio/dio.dart';

import '../../core/api/api_exception.dart';

/// Maps API/network failures to short user-facing copy.
String authErrorMessage(Object error) {
  if (error is DioException) {
    final api = ApiException.fromDio(error);
    if (api != null) {
      final code = api.statusCode;
      final msg = api.message;
      if (code == 401) {
        return 'Invalid email or password.';
      }
      if (code == 409) {
        return msg.isNotEmpty
            ? msg
            : 'That email is already registered.';
      }
      if (code == 400) {
        return msg.isNotEmpty ? msg : 'Check your input and try again.';
      }
      if (code >= 500) {
        return 'Server error. Please try again later.';
      }
      return msg.isNotEmpty ? msg : 'Something went wrong.';
    }
    return error.message?.isNotEmpty == true
        ? error.message!
        : 'Network error. Try again.';
  }
  return error.toString();
}
