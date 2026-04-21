import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mira_vpn_app/core/api/auth_api.dart';
import 'package:mira_vpn_app/core/api/models/auth_response_dto.dart';
import 'package:mira_vpn_app/core/api/models/user_dto.dart';
import 'package:mira_vpn_app/core/providers/dependency_providers.dart';
import 'package:mira_vpn_app/core/storage/token_store.dart';
import 'package:mira_vpn_app/features/auth/sign_in_screen.dart';
import 'package:mira_vpn_app/features/auth/sign_up_screen.dart';

UserDto get _user => UserDto(
      id: 'u1',
      email: 'ok@example.com',
      isPro: false,
      createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
    );

class _MemStore implements TokenStore {
  String? v;
  @override
  Future<String?> read() async => v;
  @override
  Future<void> write(String token) async => v = token;
  @override
  Future<void> delete() async => v = null;
}

class _StubAuthApi implements AuthApi {
  _StubAuthApi({
    this.loginResult,
    this.loginError,
    this.registerError,
  });

  final AuthResponseDto? loginResult;
  final Object? loginError;
  final Object? registerError;

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
    if (registerError != null) throw registerError!;
    throw StateError('register not stubbed');
  }

  @override
  Future<AuthResponseDto> socialGoogle({
    required String idToken,
    bool isPro = false,
  }) async =>
      throw StateError('socialGoogle not stubbed');

  @override
  Future<AuthResponseDto> socialApple({
    required String idToken,
    bool isPro = false,
  }) async =>
      throw StateError('socialApple not stubbed');

  @override
  Future<UserDto> me() async {
    throw StateError('me not stubbed');
  }
}

GoRouter _testRouter({required String initial}) {
  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('HOME')),
      ),
      GoRoute(
        path: '/auth/sign-in',
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/sign-up',
        builder: (_, __) => const SignUpScreen(),
      ),
    ],
  );
}

void main() {
  testWidgets('sign-in shows validation errors', (tester) async {
    final store = _MemStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          authApiProvider.overrideWithValue(_StubAuthApi()),
        ],
        child: MaterialApp.router(
          routerConfig: _testRouter(initial: '/auth/sign-in'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('sign-in navigates to sign up', (tester) async {
    final store = _MemStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          authApiProvider.overrideWithValue(_StubAuthApi()),
        ],
        child: MaterialApp.router(
          routerConfig: _testRouter(initial: '/auth/sign-in'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('link-to-sign-up')));
    await tester.pumpAndSettle();

    expect(find.text('Sign up'), findsWidgets);
  });

  testWidgets('sign-in success goes home', (tester) async {
    final store = _MemStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          authApiProvider.overrideWithValue(
            _StubAuthApi(
              loginResult: AuthResponseDto(token: 't', user: _user),
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: _testRouter(initial: '/auth/sign-in'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('sign-in-email')), 'ok@example.com');
    await tester.enterText(
        find.byKey(const Key('sign-in-password')), 'password12');
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('sign-in shows banner on 401', (tester) async {
    final store = _MemStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          authApiProvider.overrideWithValue(
            _StubAuthApi(
              loginError: DioException(
                requestOptions: RequestOptions(path: '/auth/login'),
                response: Response(
                  requestOptions: RequestOptions(),
                  statusCode: 401,
                  data: 'invalid credentials',
                ),
              ),
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: _testRouter(initial: '/auth/sign-in'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('sign-in-email')), 'ok@example.com');
    await tester.enterText(
        find.byKey(const Key('sign-in-password')), 'password12');
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Invalid email or password'), findsOneWidget);
  });

  testWidgets('sign-up shows banner on 409', (tester) async {
    final store = _MemStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          authApiProvider.overrideWithValue(
            _StubAuthApi(
              registerError: DioException(
                requestOptions: RequestOptions(path: '/auth/register'),
                response: Response(
                  requestOptions: RequestOptions(),
                  statusCode: 409,
                  data: 'email already exists',
                ),
              ),
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: _testRouter(initial: '/auth/sign-up'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('sign-up-email')), 'taken@example.com');
    await tester.enterText(
        find.byKey(const Key('sign-up-password')), 'password12');
    await tester.tap(find.byKey(const Key('sign-up-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('email already exists'), findsOneWidget);
  });
}
