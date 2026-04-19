import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/vpn/vpn_providers.dart';
import 'features/auth/auth_controller.dart';
import 'core/routing/router.dart';
import 'core/theme/app_theme.dart';

class MiraVpnApp extends ConsumerWidget {
  const MiraVpnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authControllerProvider);
    ref.watch(vpnControllerProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Mira VPN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
