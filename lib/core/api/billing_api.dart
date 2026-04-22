import 'package:dio/dio.dart';

class BillingApi {
  BillingApi(this._dio);

  final Dio _dio;

  Future<void> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String platform,
  }) async {
    await _dio.post<void>(
      '/billing/verify',
      data: <String, dynamic>{
        'productId': productId,
        'purchaseToken': purchaseToken,
        'platform': platform,
      },
    );
  }
}
