import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mira_vpn_app/core/api/auth_api.dart';
import 'package:mira_vpn_app/core/api/models/auth_response_dto.dart';
import 'package:mira_vpn_app/core/api/models/user_dto.dart';
import 'package:mira_vpn_app/core/providers/dependency_providers.dart';
import 'package:mira_vpn_app/core/storage/token_store.dart';
import 'package:mira_vpn_app/features/auth/auth_controller.dart';
import 'package:mira_vpn_app/features/me/me_screen.dart';

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
  _StubAuthApi({this.meUser});

  final UserDto? meUser;

  @override
  Future<AuthResponseDto> login({
    required String email,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<AuthResponseDto> register({
    required String email,
    required String password,
    bool isPro = false,
  }) async =>
      throw UnimplementedError();

  @override
  Future<UserDto> me() async {
    if (meUser != null) return meUser!;
    throw StateError('no user');
  }
}

void main() {
  testWidgets('signed out shows sign in card', (tester) async {
    final store = _MemStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          authApiProvider.overrideWithValue(_StubAuthApi()),
        ],
        child: const MaterialApp(home: MeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.byKey(const Key('me-sign-in')), findsOneWidget);
    expect(find.byKey(const Key('me-sign-up')), findsOneWidget);
  });

  testWidgets('signed in shows email and plan', (tester) async {
    final store = _MemStore()..v = 'tok';
    final user = UserDto(
      id: '1',
      email: 'user@test.com',
      isPro: false,
      createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          authApiProvider.overrideWithValue(_StubAuthApi(meUser: user)),
        ],
        child: const MaterialApp(home: MeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('user@test.com'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
    expect(find.byKey(const Key('me-sign-out')), findsOneWidget);
  });

  testWidgets('sign out clears session', (tester) async {
    final store = _MemStore()..v = 'tok';
    final user = UserDto(
      id: '1',
      email: 'user@test.com',
      isPro: true,
      createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
    );
    final container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(store),
        authApiProvider.overrideWithValue(_StubAuthApi(meUser: user)),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/me',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '/me',
          builder: (_, __) => const MeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(authControllerProvider).isSignedIn, isTrue);

    await tester.tap(find.byKey(const Key('me-sign-out')));
    await tester.pumpAndSettle();

    expect(store.v, isNull);
    expect(container.read(authControllerProvider).isSignedIn, isFalse);
  });

  testWidgets('Upgrade navigates to premium route', (tester) async {
    final store = _MemStore()..v = 'tok';
    final user = UserDto(
      id: '1',
      email: 'u@test.com',
      isPro: false,
      createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
    );
    final router = GoRouter(
      initialLocation: '/me',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '/premium',
          builder: (_, __) => const Scaffold(body: Text('PREMIUM_TAB')),
        ),
        GoRoute(
          path: '/me',
          builder: (_, __) => const MeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          authApiProvider.overrideWithValue(_StubAuthApi(meUser: user)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('me-upgrade')));
    await tester.pumpAndSettle();

    expect(find.text('PREMIUM_TAB'), findsOneWidget);
  });
}
