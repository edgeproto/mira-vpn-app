import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mira_vpn_app/core/api/models/user_dto.dart';
import 'package:mira_vpn_app/core/providers/dependency_providers.dart';
import 'package:mira_vpn_app/features/auth/auth_controller.dart';

class _SignedOutAuth extends AuthController {
  @override
  AuthState build() => const AuthState(isLoading: false, user: null);
}

class _FreeUserAuth extends AuthController {
  @override
  AuthState build() => AuthState(
    isLoading: false,
    user: UserDto(
      id: 'u1',
      email: 'free@example.com',
      isPro: false,
      createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
    ),
  );
}

class _ProUserAuth extends AuthController {
  @override
  AuthState build() => AuthState(
    isLoading: false,
    user: UserDto(
      id: 'u2',
      email: 'pro@example.com',
      isPro: true,
      createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
    ),
  );
}

void main() {
  test('isFreeTierProvider is true when signed out', () {
    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(_SignedOutAuth.new)],
    );
    addTearDown(container.dispose);
    expect(container.read(isFreeTierProvider), isTrue);
  });

  test('isFreeTierProvider is true for free user', () {
    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(_FreeUserAuth.new)],
    );
    addTearDown(container.dispose);
    expect(container.read(isFreeTierProvider), isTrue);
  });

  test('isFreeTierProvider is false for pro user', () {
    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(_ProUserAuth.new)],
    );
    addTearDown(container.dispose);
    expect(container.read(isFreeTierProvider), isFalse);
  });
}
