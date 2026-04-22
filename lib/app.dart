import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/vpn/vpn_providers.dart';
import 'features/auth/auth_controller.dart';
import 'core/routing/router.dart';
import 'core/theme/app_theme.dart';

class MiraVpnApp extends ConsumerStatefulWidget {
  const MiraVpnApp({super.key});

  @override
  ConsumerState<MiraVpnApp> createState() => _MiraVpnAppState();
}

class _MiraVpnAppState extends ConsumerState<MiraVpnApp> {
  static const _minimumSplashDuration = Duration(milliseconds: 1800);

  bool get _isTestEnv =>
      WidgetsBinding.instance.runtimeType.toString() ==
      'AutomatedTestWidgetsFlutterBinding';

  bool _minSplashElapsed = false;

  @override
  void initState() {
    super.initState();
    if (_isTestEnv) {
      _minSplashElapsed = true;
      return;
    }
    Future<void>.delayed(_minimumSplashDuration, () {
      if (!mounted) return;
      setState(() => _minSplashElapsed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    ref.watch(vpnControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final router = ref.watch(goRouterProvider);
    final showBootSplash = !_isTestEnv && (!_minSplashElapsed || auth.isLoading);

    return MaterialApp.router(
      title: 'Mira VPN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (child != null) child,
            if (showBootSplash) const _BootSplashOverlay(),
          ],
        );
      },
    );
  }
}

class _BootSplashOverlay extends StatefulWidget {
  const _BootSplashOverlay();

  @override
  State<_BootSplashOverlay> createState() => _BootSplashOverlayState();
}

class _BootSplashOverlayState extends State<_BootSplashOverlay> {
  static const _splashAspectRatio = 473 / 1024;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: ColoredBox(
        color: const Color(0xFF061B57),
        child: Center(
          child: AspectRatio(
            aspectRatio: _splashAspectRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/icons/splash_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
