import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../features/auth/auth_controller.dart';
import '../api/api_exception.dart';
import '../providers/dependency_providers.dart';
import 'billing_constants.dart';
import 'in_app_purchase_client.dart';

@immutable
class BillingState {
  const BillingState({
    this.isLoading = false,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.storeAvailable = false,
    this.products = const <ProductDetails>[],
    this.selectedProductId,
    this.errorMessage,
    this.infoMessage,
  });

  final bool isLoading;
  final bool isPurchasing;
  final bool isRestoring;
  final bool storeAvailable;
  final List<ProductDetails> products;
  final String? selectedProductId;
  final String? errorMessage;
  final String? infoMessage;

  ProductDetails? get selectedProduct {
    final id = selectedProductId;
    if (id == null) return null;
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  BillingState copyWith({
    bool? isLoading,
    bool? isPurchasing,
    bool? isRestoring,
    bool? storeAvailable,
    List<ProductDetails>? products,
    String? selectedProductId,
    String? errorMessage,
    String? infoMessage,
    bool clearErrorMessage = false,
    bool clearInfoMessage = false,
  }) {
    return BillingState(
      isLoading: isLoading ?? this.isLoading,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRestoring: isRestoring ?? this.isRestoring,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      products: products ?? this.products,
      selectedProductId: selectedProductId ?? this.selectedProductId,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfoMessage ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

class BillingController extends Notifier<BillingState> {
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  @override
  BillingState build() {
    final iap = ref.read(inAppPurchaseClientProvider);
    _purchaseSub = iap.purchaseStream.listen(_onPurchaseUpdates);
    ref.onDispose(() => _purchaseSub?.cancel());
    Future.microtask(loadProducts);
    return const BillingState(isLoading: true);
  }

  Future<void> loadProducts() async {
    try {
      final iap = ref.read(inAppPurchaseClientProvider);
      final available = await iap.isAvailable();
      if (!available) {
        state = state.copyWith(
          isLoading: false,
          storeAvailable: false,
          errorMessage: 'Play billing is unavailable on this device.',
        );
        return;
      }

      final response = await iap.queryProductDetails({
        BillingConstants.monthlyProductId,
        BillingConstants.annualProductId,
      });
      final products = response.productDetails.toList()
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      final selected = products.isNotEmpty ? products.first.id : null;
      state = state.copyWith(
        isLoading: false,
        storeAvailable: true,
        products: products,
        selectedProductId: selected,
        clearErrorMessage: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        storeAvailable: false,
        errorMessage: 'Play billing is unavailable on this device.',
      );
    }
  }

  void selectProduct(String productId) {
    state = state.copyWith(selectedProductId: productId, clearErrorMessage: true);
  }

  Future<void> continuePurchase() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isSignedIn) {
      state = state.copyWith(errorMessage: 'Sign in before upgrading.');
      return;
    }
    final product = state.selectedProduct;
    if (product == null) {
      state = state.copyWith(errorMessage: 'Choose a plan to continue.');
      return;
    }
    state = state.copyWith(isPurchasing: true, clearErrorMessage: true);
    await ref.read(inAppPurchaseClientProvider).buy(product);
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(
      isRestoring: true,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );
    await ref.read(inAppPurchaseClientProvider).restorePurchases();
  }

  void clearMessages() {
    state = state.copyWith(clearErrorMessage: true, clearInfoMessage: true);
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> updates) async {
    for (final purchase in updates) {
      if (purchase.status == PurchaseStatus.pending) {
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        state = state.copyWith(
          isPurchasing: false,
          isRestoring: false,
          errorMessage:
              purchase.error?.message ?? 'Purchase failed. Please try again.',
        );
        if (purchase.pendingCompletePurchase) {
          await ref.read(inAppPurchaseClientProvider).completePurchase(purchase);
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.canceled) {
        state = state.copyWith(
          isPurchasing: false,
          isRestoring: false,
          infoMessage: 'Purchase canceled.',
        );
        if (purchase.pendingCompletePurchase) {
          await ref.read(inAppPurchaseClientProvider).completePurchase(purchase);
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _verifyAndSync(purchase);
        if (purchase.pendingCompletePurchase) {
          await ref.read(inAppPurchaseClientProvider).completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _verifyAndSync(PurchaseDetails purchase) async {
    final token = purchase.verificationData.serverVerificationData;
    if (token.isEmpty) {
      state = state.copyWith(
        isPurchasing: false,
        isRestoring: false,
        errorMessage: 'Missing purchase token from store.',
      );
      return;
    }

    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'unknown',
    };

    try {
      await ref
          .read(billingApiProvider)
          .verifyPurchase(
            productId: purchase.productID,
            purchaseToken: token,
            platform: platform,
          );
      state = state.copyWith(
        isPurchasing: false,
        isRestoring: false,
        infoMessage: purchase.status == PurchaseStatus.restored
            ? 'Purchases restored.'
            : 'Subscription activated.',
        clearErrorMessage: true,
      );
      unawaited(_refreshAuthAfterBilling());
    } on DioException catch (e) {
      final api = ApiException.fromDio(e);
      final msg = (api?.statusCode == 404)
          ? 'Billing verification endpoint is not ready on backend.'
          : (api?.message ?? 'Could not verify purchase.');
      state = state.copyWith(
        isPurchasing: false,
        isRestoring: false,
        errorMessage: msg,
      );
    } catch (_) {
      state = state.copyWith(
        isPurchasing: false,
        isRestoring: false,
        errorMessage: 'Could not verify purchase.',
      );
    }
  }

  Future<void> _refreshAuthAfterBilling() async {
    try {
      await ref.read(authControllerProvider.notifier).refreshMe();
    } catch (_) {
      // Billing success should not be blocked by a failed auth refresh.
    }
  }
}

final inAppPurchaseClientProvider = Provider<InAppPurchaseClient>(
  (ref) => StoreInAppPurchaseClient(),
);

final billingControllerProvider =
    NotifierProvider<BillingController, BillingState>(BillingController.new);
