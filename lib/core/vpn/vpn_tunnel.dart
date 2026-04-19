import 'vpn_tunnel_contract.dart';
import 'vpn_tunnel_stub.dart' if (dart.library.io) 'vpn_tunnel_io.dart' as impl;

VpnTunnelAdapter createVpnTunnelAdapter() => impl.createVpnTunnelAdapter();
