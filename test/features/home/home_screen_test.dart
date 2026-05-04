import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mira_vpn_app/core/ads/ads_controller.dart';
import 'package:mira_vpn_app/core/api/models/wireguard_location_dto.dart';
import 'package:mira_vpn_app/core/providers/dependency_providers.dart';
import 'package:mira_vpn_app/core/vpn/vpn_controller.dart';
import 'package:mira_vpn_app/core/vpn/vpn_location_provider.dart';
import 'package:mira_vpn_app/core/vpn/vpn_providers.dart';
import 'package:mira_vpn_app/features/home/home_connection_state.dart';
import 'package:mira_vpn_app/features/home/home_screen.dart';

class _StubVpnLocation extends VpnLocationController {
  @override
  Future<VpnLocationState> build() async => const VpnLocationState(
        locations: [
          WireguardLocationDto(name: 'Finland', displayName: 'Finland'),
        ],
        selectedName: 'Finland',
      );
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('HomeContent shows disconnected, preparing, connecting, and connected copy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeContent(state: HomeConnectionState.disconnected),
        ),
      ),
    );
    expect(find.text('VPN is OFF'), findsOneWidget);
    expect(find.text('Finland'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeContent(state: HomeConnectionState.preparing),
        ),
      ),
    );
    expect(find.text('Preparing…'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeContent(state: HomeConnectionState.connecting),
        ),
      ),
    );
    expect(find.text('Connecting…'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeContent(state: HomeConnectionState.connected),
        ),
      ),
    );
    expect(find.text('VPN is ON'), findsOneWidget);
  });

  testWidgets('HomeContent error shows title and detail', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeContent(
            state: HomeConnectionState.error,
            errorMessage: 'Sign in to connect',
          ),
        ),
      ),
    );
    expect(find.text("Couldn't connect"), findsOneWidget);
    expect(find.text('Sign in to connect'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('disconnected shows power icon; connected shows shield', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeContent(state: HomeConnectionState.disconnected),
        ),
      ),
    );
    expect(find.byIcon(Icons.power_settings_new_rounded), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeContent(state: HomeConnectionState.connected),
        ),
      ),
    );
    expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
  });

  testWidgets('HomeScreen reflects vpn controller debug state', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        vpnLocationControllerProvider.overrideWith(_StubVpnLocation.new),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.text('VPN is OFF'), findsOneWidget);

    container.read(vpnControllerProvider.notifier).debugSetStateForTest(
          const VpnState(phase: VpnPhase.connecting),
        );
    await tester.pump();
    expect(find.text('Connecting…'), findsOneWidget);

    container.read(vpnControllerProvider.notifier).debugSetStateForTest(
          const VpnState(phase: VpnPhase.connected),
        );
    await tester.pump();
    expect(find.text('VPN is ON'), findsOneWidget);
  });

  testWidgets('connected with stats shows traffic rows', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HomeContent(
            state: HomeConnectionState.connected,
            stats: VpnTrafficStats(
              totalDownloadBytes: 2048,
              totalUploadBytes: 1024,
              downloadSpeedBps: 256,
              uploadSpeedBps: 128,
              uptime: Duration(minutes: 3, seconds: 30),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Uptime'), findsOneWidget);
  });

  testWidgets('free tier shows interstitial before connect press', (
    WidgetTester tester,
  ) async {
    final ads = _FakeAdsController();
    final vpn = _CountingVpnController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vpnLocationControllerProvider.overrideWith(_StubVpnLocation.new),
          adsControllerProvider.overrideWithValue(ads),
          isFreeTierProvider.overrideWithValue(true),
          vpnControllerProvider.overrideWith(() => vpn),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.power_settings_new_rounded));
    await tester.pump();

    expect(ads.interstitialCalls, 1);
    expect(vpn.pressCount, 1);
  });

  testWidgets('pro tier skips interstitial before connect press', (
    WidgetTester tester,
  ) async {
    final ads = _FakeAdsController();
    final vpn = _CountingVpnController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vpnLocationControllerProvider.overrideWith(_StubVpnLocation.new),
          adsControllerProvider.overrideWithValue(ads),
          isFreeTierProvider.overrideWithValue(false),
          vpnControllerProvider.overrideWith(() => vpn),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.power_settings_new_rounded));
    await tester.pump();

    expect(ads.interstitialCalls, 0);
    expect(vpn.pressCount, 1);
  });
}

class _FakeAdsController implements AdsController {
  int interstitialCalls = 0;

  @override
  bool get supportsAds => true;

  @override
  bool shouldShowBanner({required bool isFreeTier}) => isFreeTier;

  @override
  Future<void> showInterstitialBeforeConnectIfEligible({
    required bool isFreeTier,
  }) async {
    if (isFreeTier) {
      interstitialCalls++;
    }
  }
}

class _CountingVpnController extends VpnController {
  int pressCount = 0;

  @override
  VpnState build() => const VpnState(phase: VpnPhase.disconnected);

  @override
  Future<void> onCirclePressed() async {
    pressCount++;
  }
}
