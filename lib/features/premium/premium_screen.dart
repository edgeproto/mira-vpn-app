import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/billing/billing_constants.dart';
import '../../core/billing/billing_controller.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/widgets/primary_button.dart';
import '../../core/theme/widgets/section_card.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billingControllerProvider);
    final controller = ref.read(billingControllerProvider.notifier);

    if (state.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        controller.clearMessages();
      });
    }
    if (state.infoMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(state.infoMessage!)));
        controller.clearMessages();
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Go Pro')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Unlock unlimited speed and remove ads.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.products.isEmpty)
              const SectionCard(
                child: Text('Plans are unavailable right now.'),
              )
            else ...[
              for (final product in state.products) ...[
                _PlanCard(
                  title: _planTitle(product.id),
                  subtitle: product.description,
                  price: product.price,
                  selected: state.selectedProductId == product.id,
                  onTap: () => controller.selectProduct(product.id),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              key: const Key('premium-continue'),
              label: state.isPurchasing ? 'Processing…' : 'Continue',
              onPressed: state.isPurchasing || state.isLoading
                  ? null
                  : () => controller.continuePurchase(),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              key: const Key('premium-restore'),
              onPressed: state.isRestoring
                  ? null
                  : () => controller.restorePurchases(),
              child: Text(state.isRestoring ? 'Restoring…' : 'Restore purchases'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _planTitle(String productId) {
  if (productId == BillingConstants.annualProductId) {
    return 'Annual';
  }
  if (productId == BillingConstants.monthlyProductId) {
    return 'Monthly';
  }
  return 'Plan';
}
