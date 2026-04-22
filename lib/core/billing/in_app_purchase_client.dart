import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

abstract class InAppPurchaseClient {
  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> isAvailable();

  Future<ProductDetailsResponse> queryProductDetails(Set<String> productIds);

  Future<void> buy(ProductDetails product);

  Future<void> restorePurchases();

  Future<void> completePurchase(PurchaseDetails purchase);
}

class StoreInAppPurchaseClient implements InAppPurchaseClient {
  StoreInAppPurchaseClient([InAppPurchase? instance])
    : _instance = instance ?? InAppPurchase.instance;

  final InAppPurchase _instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _instance.purchaseStream;

  @override
  Future<bool> isAvailable() => _instance.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> productIds) {
    return _instance.queryProductDetails(productIds);
  }

  @override
  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _instance.buyNonConsumable(purchaseParam: param);
  }

  @override
  Future<void> restorePurchases() => _instance.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    return _instance.completePurchase(purchase);
  }
}
