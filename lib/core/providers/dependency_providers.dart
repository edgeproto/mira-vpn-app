import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../ads/ads_controller.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../api/billing_api.dart';
import '../api/wireguard_api.dart';
import '../storage/token_store.dart';
import '../storage/wg_config_store.dart';
import '../vpn/vpn_tunnel.dart';
import '../vpn/vpn_tunnel_contract.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokens = ref.watch(tokenStoreProvider);
  return ApiClient(getToken: () => tokens.read());
});

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider).dio),
);

final wireGuardApiProvider = Provider<WireGuardApi>(
  (ref) => WireGuardApi(ref.watch(apiClientProvider).dio),
);

final billingApiProvider = Provider<BillingApi>(
  (ref) => BillingApi(ref.watch(apiClientProvider).dio),
);

final wgConfigStoreProvider = Provider<WgConfigStore>(
  (ref) => SecureWgConfigStore(),
);

final vpnTunnelAdapterProvider = Provider<VpnTunnelAdapter>(
  (ref) => createVpnTunnelAdapter(),
);

final adsControllerProvider = Provider<AdsController>(
  (ref) => GoogleMobileAdsController(),
);

final isFreeTierProvider = Provider<bool>((ref) {
  final auth = ref.watch(authControllerProvider);
  final user = auth.user;
  return user == null || !user.isPro;
});
