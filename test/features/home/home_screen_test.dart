import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mira_vpn_app/core/vpn/vpn_controller.dart';
import 'package:mira_vpn_app/core/vpn/vpn_providers.dart';
import 'package:mira_vpn_app/features/home/home_connection_state.dart';
import 'package:mira_vpn_app/features/home/home_screen.dart';

void main() {
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
    final container = ProviderContainer();
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
}
