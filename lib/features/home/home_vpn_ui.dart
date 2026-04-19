import 'package:flutter/foundation.dart';

import '../../core/vpn/vpn_controller.dart';
import 'home_connection_state.dart';

@immutable
class HomeVpnUi {
  const HomeVpnUi({
    required this.connection,
    this.errorMessage,
  });

  final HomeConnectionState connection;
  final String? errorMessage;

  factory HomeVpnUi.fromVpnState(VpnState vpn) {
    switch (vpn.phase) {
      case VpnPhase.disconnected:
        return const HomeVpnUi(connection: HomeConnectionState.disconnected);
      case VpnPhase.preparing:
        return const HomeVpnUi(connection: HomeConnectionState.preparing);
      case VpnPhase.connecting:
        return const HomeVpnUi(connection: HomeConnectionState.connecting);
      case VpnPhase.connected:
        return const HomeVpnUi(connection: HomeConnectionState.connected);
      case VpnPhase.error:
        return HomeVpnUi(
          connection: HomeConnectionState.error,
          errorMessage: vpn.message,
        );
    }
  }
}
