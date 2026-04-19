import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mira_vpn_app/app.dart';

void main() {
  testWidgets('bottom nav switches shell routes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MiraVpnApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('/'), findsOneWidget);

    await tester.tap(find.text('Premium'));
    await tester.pumpAndSettle();
    expect(find.text('/premium'), findsOneWidget);

    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    expect(find.text('/me'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('/'), findsOneWidget);
  });
}
