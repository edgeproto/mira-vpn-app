import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/widgets/section_card.dart';
import 'home_connection_provider.dart';
import 'home_connection_state.dart';
import 'widgets/connect_circle_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeConnectionProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: HomeContent(state: state),
        ),
      ),
    );
  }
}

@visibleForTesting
class HomeContent extends StatelessWidget {
  const HomeContent({super.key, required this.state});

  final HomeConnectionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusText = switch (state) {
      HomeConnectionState.disconnected => 'VPN is OFF',
      HomeConnectionState.connecting => 'Connecting…',
      HomeConnectionState.connected => 'VPN is ON',
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
        const SizedBox(height: AppSpacing.lg),
        ConnectCircleButton(state: state),
        const SizedBox(height: AppSpacing.xl),
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
