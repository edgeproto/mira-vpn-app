import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../home_connection_state.dart';

/// Large circular connect control; [onPressed] is null for display-only (e.g. golden tests).
class ConnectCircleButton extends StatelessWidget {
  const ConnectCircleButton({
    super.key,
    required this.state,
    this.onPressed,
  });

  final HomeConnectionState state;
  final VoidCallback? onPressed;

  static const double diameter = 168;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final semanticsLabel = switch (state) {
      HomeConnectionState.disconnected => 'Connect VPN',
      HomeConnectionState.preparing => 'VPN preparing',
      HomeConnectionState.connecting => 'VPN connecting',
      HomeConnectionState.connected => 'Disconnect VPN',
      HomeConnectionState.error => 'Retry VPN',
    };

    final child = SizedBox(
      width: diameter,
      height: diameter,
      child: switch (state) {
        HomeConnectionState.disconnected => _OutlinedCircle(
            child: Icon(
              Icons.power_settings_new_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
          ),
        HomeConnectionState.preparing => _OutlinedCircle(
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        HomeConnectionState.connecting => _OutlinedCircle(
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        HomeConnectionState.connected => DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 56,
              color: Colors.white,
            ),
          ),
        HomeConnectionState.error => _OutlinedCircle(
            child: Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: theme.colorScheme.error,
            ),
          ),
      },
    );

    final wrapped = onPressed == null
        ? child
        : Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: child,
            ),
          );

    return Semantics(
      label: semanticsLabel,
      button: onPressed != null,
      child: wrapped,
    );
  }
}

class _OutlinedCircle extends StatelessWidget {
  const _OutlinedCircle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.6),
          width: 3,
        ),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      ),
      child: Center(child: child),
    );
  }
}
