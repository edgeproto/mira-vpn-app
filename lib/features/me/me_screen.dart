import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/models/user_dto.dart';
import '../../core/billing/billing_controller.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/widgets/primary_button.dart';
import '../../core/theme/widgets/section_card.dart';
import '../auth/auth_controller.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    if (auth.isLoading && !auth.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: const Center(child: Text('Loading…')),
      );
    }

    if (!auth.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sign in',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Create an account or sign in to sync your subscription and VPN settings.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      key: const Key('me-sign-in'),
                      label: 'Sign in',
                      onPressed: () => context.push('/auth/sign-in'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      key: const Key('me-sign-up'),
                      onPressed: () => context.push('/auth/sign-up'),
                      child: const Text('Create account'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _SignedInHeader(user: auth.user!),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              key: const Key('me-upgrade'),
              onPressed: () => context.go('/premium'),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Upgrade'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              key: const Key('me-restore'),
              onPressed: () => _restorePurchases(context, ref),
              icon: const Icon(Icons.restore_outlined),
              label: const Text('Restore'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              key: const Key('me-about'),
              onPressed: () => _showAbout(context),
              icon: const Icon(Icons.info_outline),
              label: const Text('About'),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              key: const Key('me-sign-out'),
              onPressed: () => _signOut(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;
    context.go('/');
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    await ref.read(billingControllerProvider.notifier).restorePurchases();
    if (!context.mounted) return;
    final state = ref.read(billingControllerProvider);
    final msg = state.errorMessage ?? state.infoMessage ?? 'Restore requested.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Mira VPN',
      applicationVersion: '1.0.0',
      applicationLegalese: '© Mira VPN',
      children: [
        const Padding(
          padding: EdgeInsets.only(top: AppSpacing.md),
          child: Text(
            'WireGuard client for Android. Phase 1 preview.',
          ),
        ),
      ],
    );
  }
}

class _SignedInHeader extends StatelessWidget {
  const _SignedInHeader({required this.user});

  final UserDto user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = user.isPro ? 'Pro' : 'Free';

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Signed in', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            user.email,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Plan', style: theme.textTheme.bodyMedium),
              const SizedBox(width: AppSpacing.sm),
              Chip(
                label: Text(plan),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
