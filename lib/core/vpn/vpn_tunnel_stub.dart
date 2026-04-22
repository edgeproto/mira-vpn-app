import 'dart:async';

import 'vpn_tunnel_contract.dart';

class StubVpnTunnelAdapter implements VpnTunnelAdapter {
  @override
  bool get supported => false;

  @override
  Stream<String> get stageEvents => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get trafficEvents => const Stream.empty();

  @override
  Future<void> initialize({
    required String interfaceName,
    String? vpnName,
    String? iosAppGroup,
  }) async {}

  @override
  Future<void> startVpn({
    required String serverAddress,
    required String wgQuickConfig,
    required String providerBundleIdentifier,
  }) async {}

  @override
  Future<void> stopVpn() async {}

  @override
  Future<bool> checkVpnPermission() async => false;

  @override
  Future<void> refreshStage() async {}

  @override
  Future<String> stage() async => 'disconnected';
}

VpnTunnelAdapter createVpnTunnelAdapter() => StubVpnTunnelAdapter();
