import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_connection_state.dart';

/// Fake controller for Home UI; replace with [VpnController] when integrating VPN.
final homeConnectionProvider =
    StateProvider<HomeConnectionState>((ref) => HomeConnectionState.disconnected);
