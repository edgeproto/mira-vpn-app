import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vpn_controller.dart';

final vpnControllerProvider =
    NotifierProvider<VpnController, VpnState>(VpnController.new);
