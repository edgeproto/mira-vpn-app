/// Platform VPN tunnel (WireGuard on IO; no-op on web).
abstract class VpnTunnelAdapter {
  bool get supported;

  Stream<String> get stageEvents;
  Stream<Map<String, dynamic>> get trafficEvents;

  Future<void> initialize({
    required String interfaceName,
    String? vpnName,
    String? iosAppGroup,
  });

  Future<void> startVpn({
    required String serverAddress,
    required String wgQuickConfig,
    required String providerBundleIdentifier,
  });

  Future<void> stopVpn();

  Future<bool> checkVpnPermission();

  Future<void> refreshStage();
  Future<String> stage();
}
