import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mira_vpn_app/core/api/auth_api.dart';
import 'package:mira_vpn_app/core/api/models/auth_response_dto.dart';
import 'package:mira_vpn_app/core/api/models/user_dto.dart';
import 'package:mira_vpn_app/core/providers/dependency_providers.dart';
import 'package:mira_vpn_app/core/storage/token_store.dart';
import 'package:mira_vpn_app/features/auth/auth_controller.dart';

UserDto get _sampleUser => UserDto(
      id: 'u1',
      email: 'a@example.com',
      isPro: false,
      createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
    );

Future<void> _waitUntil(
  bool Function() satisfied, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (satisfied()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('condition not met within $timeout');
}

void main() {
  group('AuthController', () {
    test('login success stores token and signs in', () async {
      final store = _FakeTokenStore();
      final auth = _FakeAuthApi(
        loginResult: AuthResponseDto(token: 'jwt-1', user: _sampleUser),
      );
      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          authApiProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _waitUntil(() => !container.read(authControllerProvider).isLoading);

      await container.read(authControllerProvider.notifier).login(
            'a@example.com',
            'password12',
          );

      expect(store.value, 'jwt-1');
      final st = container.read(authControllerProvider);
      expect(st.isSignedIn, isTrue);
      expect(st.user?.email, 'a@example.com');
    });

    test('login failure leaves signed out and rethrows', () async {
      final store = _FakeTokenStore();
      final auth = _FakeAuthApi(
        loginError: DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 401,
            data: 'invalid credentials',
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          authApiProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _waitUntil(() => !container.read(authControllerProvider).isLoading);

      await expectLater(
        container.read(authControllerProvider.notifier).login(
              'a@example.com',
              'wrong',
            ),
        throwsA(isA<DioException>()),
      );

      expect(store.value, isNull);
      expect(container.read(authControllerProvider).isSignedIn, isFalse);
    });

    test('hydrate signs in when token exists and me succeeds', () async {
      final store = _FakeTokenStore()..value = 'existing';
      final auth = _FakeAuthApi(meResult: _sampleUser);
      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          authApiProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);

      await _waitUntil(() => container.read(authControllerProvider).isSignedIn);

      expect(container.read(authControllerProvider).user?.id, 'u1');
    });
  });
}

class _FakeTokenStore implements TokenStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async {
    value = token;
  }

  @override
  Future<void> delete() async {
    value = null;
  }
}

class _FakeAuthApi implements AuthApi {
  _FakeAuthApi({
    this.loginResult,
    this.meResult,
    this.loginError,
  });

  final AuthResponseDto? loginResult;
  final UserDto? meResult;
  final Object? loginError;

  @override
  Future<AuthResponseDto> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) throw loginError!;
    if (loginResult != null) return loginResult!;
    throw StateError('login not stubbed');
  }

  @override
  Future<AuthResponseDto> register({
    required String email,
    required String password,
    bool isPro = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserDto> me() async {
    if (meResult != null) return meResult!;
    throw StateError('me not stubbed');
  }
}
