import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mira_vpn_app/features/auth/auth_error_message.dart';

void main() {
  test('maps 401 and 5xx', () {
    expect(
      authErrorMessage(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 401,
            data: 'invalid credentials',
          ),
        ),
      ),
      'Invalid email or password.',
    );

    expect(
      authErrorMessage(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 503,
            data: 'upstream',
          ),
        ),
      ),
      'Server error. Please try again later.',
    );
  });
}
