import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/widgets/section_card.dart';
import '../../core/vpn/vpn_controller.dart';
import '../../core/vpn/vpn_providers.dart';
import 'home_connection_state.dart';
import 'home_vpn_provider.dart';
import 'widgets/connect_circle_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(vpnControllerProvider.notifier).onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(homeVpnUiProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: HomeContent(
            state: ui.connection,
            errorMessage: ui.errorMessage,
            stats: ui.stats,
            onCirclePressed: () =>
                ref.read(vpnControllerProvider.notifier).onCirclePressed(),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.state,
    this.errorMessage,
    this.stats,
    this.onCirclePressed,
  });

  final HomeConnectionState state;
  final String? errorMessage;
  final VpnTrafficStats? stats;
  final VoidCallback? onCirclePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusText = switch (state) {
      HomeConnectionState.disconnected => 'VPN is OFF',
      HomeConnectionState.preparing => 'Preparing…',
      HomeConnectionState.connecting => 'Connecting…',
      HomeConnectionState.connected => 'VPN is ON',
      HomeConnectionState.error => "Couldn't connect",
    };

    return Column(
      children: [
        const Spacer(flex: 2),
        Text(
          statusText,
          key: ValueKey<String>(statusText),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        if (state == HomeConnectionState.error &&
            (errorMessage ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: onCirclePressed,
            child: const Text('Retry'),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ConnectCircleButton(
          state: state,
          onPressed: onCirclePressed,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (state == HomeConnectionState.connected && stats != null) ...[
          SectionCard(
            child: Column(
              children: [
                _StatRow(
                  label: 'Download',
                  value: '${_formatBytes(stats!.totalDownloadBytes)} (${_formatSpeed(stats!.downloadSpeedBps)})',
                ),
                const SizedBox(height: AppSpacing.sm),
                _StatRow(
                  label: 'Upload',
                  value: '${_formatBytes(stats!.totalUploadBytes)} (${_formatSpeed(stats!.uploadSpeedBps)})',
                ),
                const SizedBox(height: AppSpacing.sm),
                _StatRow(
                  label: 'Total',
                  value: _formatBytes(stats!.totalDownloadBytes + stats!.totalUploadBytes),
                ),
                const SizedBox(height: AppSpacing.sm),
                _StatRow(
                  label: 'Uptime',
                  value: _formatUptime(stats!.uptime),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SectionCard(
          child: Row(
            children: [
              Icon(
                Icons.public_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Finland',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _formatBytes(int bytes) {
  const suffixes = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < suffixes.length - 1) {
    size /= 1024;
    unit++;
  }
  final precision = size >= 10 || unit == 0 ? 0 : 1;
  return '${size.toStringAsFixed(precision)} ${suffixes[unit]}';
}

String _formatSpeed(double bytesPerSecond) {
  return '${_formatBytes(bytesPerSecond.round())}/s';
}

String _formatUptime(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
