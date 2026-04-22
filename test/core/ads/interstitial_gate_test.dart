import 'package:flutter_test/flutter_test.dart';
import 'package:mira_vpn_app/core/ads/interstitial_gate.dart';

void main() {
  test('allows first show then enforces cooldown', () {
    var now = DateTime(2026, 1, 1, 12, 0, 0);
    final gate = InterstitialGate(
      cooldown: const Duration(minutes: 10),
      now: () => now,
    );

    expect(gate.canShowNow(), isTrue);
    gate.markShownNow();
    expect(gate.canShowNow(), isFalse);

    now = now.add(const Duration(minutes: 9, seconds: 59));
    expect(gate.canShowNow(), isFalse);

    now = now.add(const Duration(seconds: 1));
    expect(gate.canShowNow(), isTrue);
  });
}
