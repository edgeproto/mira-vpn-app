import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mira_vpn_app/core/api/billing_api.dart';
import 'package:mira_vpn_app/core/api/models/user_dto.dart';
import 'package:mira_vpn_app/core/billing/billing_constants.dart';
import 'package:mira_vpn_app/core/billing/billing_controller.dart';
import 'package:mira_vpn_app/core/billing/in_app_purchase_client.dart';
import 'package:mira_vpn_app/core/providers/dependency_providers.dart';
import 'package:mira_vpn_app/features/auth/auth_controller.dart';

class _SignedInAuth extends AuthController {
  @override
  AuthState build() => AuthState(
    isLoading: false,
    user: UserDto(
      id: 'u1',
      email: 'user@test.com',
      isPro: false,
      createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
    ),
  );
}

class _FakeBillingApi implements BillingApi {
  int calls = 0;

  @override
  Future<void> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String platform,
  }) async {
    calls++;
  }
}

class _FakeIapClient implements InAppPurchaseClient {
  final purchases = StreamController<List<PurchaseDetails>>.broadcast();
  final products = <ProductDetails>[
    ProductDetails(
      id: BillingConstants.monthlyProductId,
      title: 'Monthly',
      description: 'Monthly plan',
      price: '\$4.99',
      rawPrice: 4.99,
      currencyCode: 'USD',
      currencySymbol: '\$',
    ),
    ProductDetails(
      id: BillingConstants.annualProductId,
      title: 'Annual',
      description: 'Annual plan',
      price: '\$39.99',
      rawPrice: 39.99,
      currencyCode: 'USD',
      currencySymbol: '\$',
    ),
  ];

  int restoreCalls = 0;
  int buyCalls = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => purchases.stream;

  @override
  Future<void> buy(ProductDetails product) async {
    buyCalls++;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> productIds) async {
    return ProductDetailsResponse(productDetails: products, notFoundIDs: const []);
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
  }
}

PurchaseDetails _purchase({
  required PurchaseStatus status,
  required String productId,
  String token = 'tok',
}) {
  return PurchaseDetails(
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: token,
      source: 'play',
    ),
    transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
    status: status,
  );
}

void main() {
  test('restore triggers store restore flow', () async {
    final iap = _FakeIapClient();
    final container = ProviderContainer(
      overrides: [
        inAppPurchaseClientProvider.overrideWithValue(iap),
        billingApiProvider.overrideWithValue(_FakeBillingApi()),
        authControllerProvider.overrideWith(_SignedInAuth.new),
      ],
    );
    addTearDown(() async {
      await iap.purchases.close();
      container.dispose();
    });

    container.read(billingControllerProvider);
    await container.read(billingControllerProvider.notifier).restorePurchases();
    expect(iap.restoreCalls, 1);
  });

  test('purchased event verifies and syncs subscription', () async {
    final iap = _FakeIapClient();
    final billingApi = _FakeBillingApi();
    final container = ProviderContainer(
      overrides: [
        inAppPurchaseClientProvider.overrideWithValue(iap),
        billingApiProvider.overrideWithValue(billingApi),
        authControllerProvider.overrideWith(_SignedInAuth.new),
      ],
    );
    addTearDown(() async {
      await iap.purchases.close();
      container.dispose();
    });

    container.read(billingControllerProvider);
    iap.purchases.add([
      _purchase(
        status: PurchaseStatus.purchased,
        productId: BillingConstants.monthlyProductId,
      ),
    ]);
    await _waitUntil(() => billingApi.calls == 1);
    await _waitUntil(
      () => container.read(billingControllerProvider).infoMessage != null,
    );

    expect(billingApi.calls, 1);
    expect(
      container.read(billingControllerProvider).infoMessage,
      'Subscription activated.',
    );
  });
}

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
