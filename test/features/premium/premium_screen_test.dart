import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mira_vpn_app/core/billing/billing_controller.dart';
import 'package:mira_vpn_app/features/premium/premium_screen.dart';

class _FakeBillingController extends BillingController {
  _FakeBillingController(this._seed);

  final BillingState _seed;
  int continueCalls = 0;
  int restoreCalls = 0;

  @override
  BillingState build() => _seed;

  @override
  Future<void> continuePurchase() async {
    continueCalls++;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
  }
}

ProductDetails _product({
  required String id,
  required String title,
  required String price,
  required double rawPrice,
}) {
  return ProductDetails(
    id: id,
    title: title,
    description: '$title subscription',
    price: price,
    rawPrice: rawPrice,
    currencyCode: 'USD',
    currencySymbol: '\$',
  );
}

void main() {
  testWidgets('shows monthly and annual plan cards', (tester) async {
    final fake = _FakeBillingController(
      BillingState(
        isLoading: false,
        storeAvailable: true,
        products: [
          _product(id: 'mira_vpn_pro_monthly', title: 'Monthly', price: '\$4.99', rawPrice: 4.99),
          _product(id: 'mira_vpn_pro_annual', title: 'Annual', price: '\$39.99', rawPrice: 39.99),
        ],
        selectedProductId: 'mira_vpn_pro_monthly',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [billingControllerProvider.overrideWith(() => fake)],
        child: const MaterialApp(home: PremiumScreen()),
      ),
    );

    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Annual'), findsOneWidget);
    expect(find.byKey(const Key('premium-continue')), findsOneWidget);
  });

  testWidgets('continue button triggers purchase flow', (tester) async {
    final fake = _FakeBillingController(
      BillingState(
        isLoading: false,
        storeAvailable: true,
        products: [
          _product(id: 'mira_vpn_pro_monthly', title: 'Monthly', price: '\$4.99', rawPrice: 4.99),
        ],
        selectedProductId: 'mira_vpn_pro_monthly',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [billingControllerProvider.overrideWith(() => fake)],
        child: const MaterialApp(home: PremiumScreen()),
      ),
    );

    await tester.tap(find.byKey(const Key('premium-continue')));
    await tester.pump();
    expect(fake.continueCalls, 1);
  });
}
