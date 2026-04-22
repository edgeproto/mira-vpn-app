class InterstitialGate {
  InterstitialGate({
    this.cooldown = const Duration(minutes: 10),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration cooldown;
  final DateTime Function() _now;
  DateTime? _lastShownAt;

  bool canShowNow() {
    final last = _lastShownAt;
    if (last == null) {
      return true;
    }
    return _now().difference(last) >= cooldown;
  }

  void markShownNow() {
    _lastShownAt = _now();
  }
}
