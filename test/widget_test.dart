import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mira_vpn_app/core/ads/ads_controller.dart';
import 'package:mira_vpn_app/core/billing/billing_controller.dart';
import 'package:mira_vpn_app/core/providers/dependency_providers.dart';

import 'package:mira_vpn_app/app.dart';

void main() {
  testWidgets('bottom nav switches shell routes', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        adsControllerProvider.overrideWithValue(_NoopAdsController()),
        billingControllerProvider.overrideWith(_StaticBillingController.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MiraVpnApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('VPN is OFF'), findsOneWidget);

    await tester.tap(find.text('Premium'));
    await tester.pumpAndSettle();
    expect(find.text('Go Pro'), findsOneWidget);

    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('VPN is OFF'), findsOneWidget);
  });
}

class _NoopAdsController implements AdsController {
  @override
  bool get supportsAds => false;

  @override
  bool shouldShowBanner({required bool isFreeTier}) => false;

  @override
  Future<void> showInterstitialBeforeConnectIfEligible({
    required bool isFreeTier,
  }) async {}
}

class _StaticBillingController extends BillingController {
  @override
  BillingState build() => const BillingState(
    isLoading: false,
    storeAvailable: true,
  );
}
