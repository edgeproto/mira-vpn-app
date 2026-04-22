import 'package:wireguard_flutter_plus/wireguard_flutter_plus.dart';

import 'vpn_tunnel_contract.dart';

class NativeVpnTunnelAdapter implements VpnTunnelAdapter {
  @override
  bool get supported => true;

  @override
  Stream<String> get stageEvents =>
      WireGuardFlutter.instance.vpnStageSnapshot.map((e) => e.name);

  @override
  Stream<Map<String, dynamic>> get trafficEvents =>
      WireGuardFlutter.instance.trafficSnapshot;

  @override
  Future<void> initialize({
    required String interfaceName,
    String? vpnName,
    String? iosAppGroup,
  }) {
    return WireGuardFlutter.instance.initialize(
      interfaceName: interfaceName,
      vpnName: vpnName,
      iosAppGroup: iosAppGroup,
    );
  }

  @override
  Future<void> startVpn({
    required String serverAddress,
    required String wgQuickConfig,
    required String providerBundleIdentifier,
  }) {
    return WireGuardFlutter.instance.startVpn(
      serverAddress: serverAddress,
      wgQuickConfig: wgQuickConfig,
      providerBundleIdentifier: providerBundleIdentifier,
    );
  }

  @override
  Future<void> stopVpn() => WireGuardFlutter.instance.stopVpn();

  @override
  Future<bool> checkVpnPermission() =>
      WireGuardFlutter.instance.checkVpnPermission();

  @override
  Future<void> refreshStage() => WireGuardFlutter.instance.refreshStage();

  @override
  Future<String> stage() => WireGuardFlutter.instance.stage().then((s) => s.name);
}

VpnTunnelAdapter createVpnTunnelAdapter() => NativeVpnTunnelAdapter();
