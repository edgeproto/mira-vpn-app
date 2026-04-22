import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:mira_vpn_app/core/api/api_exception.dart';
import 'package:mira_vpn_app/core/api/auth_api.dart';
import 'package:mira_vpn_app/core/api/billing_api.dart';
import 'package:mira_vpn_app/core/api/interceptors/auth_interceptor.dart';
import 'package:mira_vpn_app/core/api/interceptors/error_interceptor.dart';
import 'package:mira_vpn_app/core/api/wireguard_api.dart';

const _base = 'http://localhost:8080';

Map<String, dynamic> _userJson({String id = 'user-1'}) => {
      'id': id,
      'email': 'a@example.com',
      'isPro': false,
      'createdAt': '2025-01-15T12:00:00.000Z',
    };

void main() {
  group('AuthApi + WireGuardApi', () {
    late Dio dio;
    late DioAdapter adapter;

    setUp(() {
      dio = Dio(
        BaseOptions(
          baseUrl: _base,
          headers: {Headers.contentTypeHeader: Headers.jsonContentType},
        ),
      );
      dio.interceptors.addAll([
        AuthInterceptor(getToken: () async => null),
        ErrorInterceptor(),
      ]);
      adapter = DioAdapter(dio: dio);
    });

    test('register returns token and user', () async {
      adapter.onPost(
        '/auth/register',
        (server) => server.reply(
          201,
          {
            'token': 'jwt-register',
            'user': _userJson(),
          },
        ),
        data: {
          'email': 'a@example.com',
          'password': 'password12',
          'isPro': false,
        },
      );

      final api = AuthApi(dio);
      final res = await api.register(
        email: 'a@example.com',
        password: 'password12',
      );

      expect(res.token, 'jwt-register');
      expect(res.user.email, 'a@example.com');
      expect(res.user.isPro, false);
    });

    test('login returns token and user', () async {
      adapter.onPost(
        '/auth/login',
        (server) => server.reply(
          200,
          {
            'token': 'jwt-login',
            'user': _userJson(id: 'u-2'),
          },
        ),
        data: {
          'email': 'a@example.com',
          'password': 'password12',
        },
      );

      final api = AuthApi(dio);
      final res = await api.login(
        email: 'a@example.com',
        password: 'password12',
      );

      expect(res.token, 'jwt-login');
      expect(res.user.id, 'u-2');
    });

    test('me sends Bearer token', () async {
      dio.interceptors.clear();
      dio.interceptors.addAll([
        AuthInterceptor(getToken: () async => 'secret-token'),
        ErrorInterceptor(),
      ]);
      adapter = DioAdapter(dio: dio);

      adapter.onGet(
        '/auth/me',
        (server) => server.reply(200, _userJson()),
        headers: {'Authorization': 'Bearer secret-token'},
      );

      final api = AuthApi(dio);
      final user = await api.me();
      expect(user.email, 'a@example.com');
    });

    test('createConfig returns wireguard fields', () async {
      dio.interceptors.clear();
      dio.interceptors.addAll([
        AuthInterceptor(getToken: () async => 'wg-token'),
        ErrorInterceptor(),
      ]);
      adapter = DioAdapter(dio: dio);

      adapter.onPost(
        '/wireguard/config',
        (server) => server.reply(
          201,
          {
            'location': 'Finland',
            'peerId': 'peer-1',
            'address': '10.0.0.2/32',
            'publicKey': 'abc+base64=',
            'config': '[Interface]\nPrivateKey=...\n',
          },
        ),
        data: {'location': 'Finland'},
        headers: {'Authorization': 'Bearer wg-token'},
      );

      final api = WireGuardApi(dio);
      final cfg = await api.createConfig(location: 'Finland');
      expect(cfg.peerId, 'peer-1');
      expect(cfg.config.contains('[Interface]'), isTrue);
    });

    test('verifyPurchase posts billing token payload', () async {
      dio.interceptors.clear();
      dio.interceptors.addAll([
        AuthInterceptor(getToken: () async => 'billing-token'),
        ErrorInterceptor(),
      ]);
      adapter = DioAdapter(dio: dio);

      adapter.onPost(
        '/billing/verify',
        (server) => server.reply(200, {}),
        data: {
          'productId': 'mira_vpn_pro_monthly',
          'purchaseToken': 'purchase-123',
          'platform': 'android',
        },
        headers: {'Authorization': 'Bearer billing-token'},
      );

      final api = BillingApi(dio);
      await api.verifyPurchase(
        productId: 'mira_vpn_pro_monthly',
        purchaseToken: 'purchase-123',
        platform: 'android',
      );
    });
  });

  group('ErrorInterceptor', () {
    late Dio dio;
    late DioAdapter adapter;

    setUp(() {
      dio = Dio(
        BaseOptions(
          baseUrl: _base,
          headers: {Headers.contentTypeHeader: Headers.jsonContentType},
        ),
      );
      dio.interceptors.addAll([
        AuthInterceptor(getToken: () async => null),
        ErrorInterceptor(),
      ]);
      adapter = DioAdapter(dio: dio);
    });

    test('401 maps to ApiException on /auth/me', () async {
      adapter.onGet(
        '/auth/me',
        (server) => server.reply(401, 'unauthorized'),
      );

      final api = AuthApi(dio);
      await expectLater(
        api.me(),
        throwsA(
          predicate<DioException>((e) {
            expect(e.error, isA<ApiException>());
            final a = e.error! as ApiException;
            expect(a.statusCode, 401);
            expect(a.message, 'unauthorized');
            return true;
          }),
        ),
      );
    });

    test('409 maps to ApiException on wireguard config', () async {
      dio.interceptors.clear();
      dio.interceptors.addAll([
        AuthInterceptor(getToken: () async => 't'),
        ErrorInterceptor(),
      ]);
      adapter = DioAdapter(dio: dio);

      adapter.onPost(
        '/wireguard/config',
        (server) => server.reply(
          409,
          'peer already exists for location',
        ),
        data: {'location': 'Finland'},
        headers: {'Authorization': 'Bearer t'},
      );

      final api = WireGuardApi(dio);
      await expectLater(
        api.createConfig(),
        throwsA(
          predicate<DioException>((e) {
            expect(e.error, isA<ApiException>());
            final a = e.error! as ApiException;
            expect(a.statusCode, 409);
            expect(
              a.message,
              'peer already exists for location',
            );
            return true;
          }),
        ),
      );
    });
  });
}
