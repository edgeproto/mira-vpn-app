import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/vpn/vpn_providers.dart';
import 'home_vpn_ui.dart';

final homeVpnUiProvider = Provider<HomeVpnUi>(
  (ref) => HomeVpnUi.fromVpnState(ref.watch(vpnControllerProvider)),
);
