import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vpn_controller.dart';

export 'vpn_location_provider.dart';

final vpnControllerProvider =
    NotifierProvider<VpnController, VpnState>(VpnController.new);
