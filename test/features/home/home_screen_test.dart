import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mira_vpn_app/features/home/home_connection_provider.dart';
import 'package:mira_vpn_app/features/home/home_connection_state.dart';
import 'package:mira_vpn_app/features/home/home_screen.dart';

void main() {
  testWidgets('HomeContent shows disconnected, connecting, and connected copy', (
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

  testWidgets('HomeScreen reflects fake connection provider updates', (
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

    container.read(homeConnectionProvider.notifier).state =
        HomeConnectionState.connecting;
    await tester.pump();
    expect(find.text('Connecting…'), findsOneWidget);

    container.read(homeConnectionProvider.notifier).state =
        HomeConnectionState.connected;
    await tester.pump();
    expect(find.text('VPN is ON'), findsOneWidget);
  });
}
