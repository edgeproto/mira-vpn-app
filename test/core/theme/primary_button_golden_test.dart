import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mira_vpn_app/core/theme/app_theme.dart';
import 'package:mira_vpn_app/core/theme/widgets/primary_button.dart';

void main() {
  Future<void> pumpButtonCase(
    WidgetTester tester, {
    required String goldenName,
    required PrimaryButton button,
  }) async {
    final binding = tester.binding;
    await binding.setSurfaceSize(const Size(360, 200));
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('golden_capture'),
            child: Center(
              child: SizedBox(
                width: 240,
                height: 56,
                child: button,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('golden_capture')),
      matchesGoldenFile('goldens/$goldenName.png'),
    );
  }

  testWidgets('PrimaryButton idle', (WidgetTester tester) async {
    await pumpButtonCase(
      tester,
      goldenName: 'primary_button_idle',
      button: PrimaryButton(
        label: 'Connect',
        onPressed: () {},
      ),
    );
  });

  testWidgets('PrimaryButton disabled', (WidgetTester tester) async {
    await pumpButtonCase(
      tester,
      goldenName: 'primary_button_disabled',
      button: const PrimaryButton(
        label: 'Connect',
        onPressed: null,
      ),
    );
  });

  testWidgets('PrimaryButton pressed', (WidgetTester tester) async {
    final binding = tester.binding;
    await binding.setSurfaceSize(const Size(360, 200));
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('golden_capture'),
            child: Center(
              child: SizedBox(
                width: 240,
                height: 56,
                child: PrimaryButton(
                  label: 'Connect',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byType(PrimaryButton));
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 250));

    await expectLater(
      find.byKey(const Key('golden_capture')),
      matchesGoldenFile('goldens/primary_button_pressed.png'),
    );

    await gesture.up();
  });
}
