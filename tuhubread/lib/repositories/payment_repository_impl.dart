import 'package:logger/logger.dart';

import '../core/result.dart';
import '../models/cart_item.model.dart';
import '../models/order_result.model.dart';
import '../models/payment_verify_result.model.dart';
import '../services/api_service.dart';
import 'payment_repository.dart';
import '../l10n/app_strings.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

class PaymentRepositoryImpl implements PaymentRepository {
  final ApiService apiService;

  const PaymentRepositoryImpl({required this.apiService});

  @override
  Future<Result<OrderResultModel>> createVnpayPayment({
    required String addressId,
    required String deliveryOption,
    String? voucherCode,
    String? note,
    List<CartItemModel>? items,
  }) async {
    try {
      final res = await apiService.post('/api/payments/vnpay', {
        'address_id': addressId,
        'delivery_option': deliveryOption,
        'voucher_code': ?voucherCode,
        'note': ?note,
        if (items != null)
          'items': items
              .map(
                (item) => {
                  'product_id': item.productId,
                  'variant_id': item.variantId,
                  'product_name': item.productName,
                  'variant_name': item.variantName,
                  'product_image': item.image,
                  'shop_id': item.shopId,
                  'quantity': item.quantity,
                  'unit_price': item.unitPrice,
                  'selected_options': item.selectedOptionIds
                      .map((id) => {'option_id': id})
                      .toList(),
                },
              )
              .toList(),
      });

      if (res['data'] != null) {
        return Success(
          OrderResultModel.fromJson(res['data'] as Map<String, dynamic>),
        );
      }
      return Failure(res['msg'] ?? AppStrings.current.errorCreateVnpayLink);
    } catch (e, s) {
      _log.e('[createVnpayPayment] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectPayment);
    }
  }

  @override
  Future<Result<PaymentVerifyResult>> verifyPayment({
    required String txnRef,
  }) async {
    try {
      final res = await apiService.get(
        '/api/payment/vnpay-verify',
        query: {'txnRef': txnRef},
      );

      if (res['data'] != null) {
        return Success(
          PaymentVerifyResult.fromJson(
            res['data'] as Map<String, dynamic>,
          ),
        );
      }
      return Failure(res['msg'] ?? AppStrings.current.errorVerifyTransaction);
    } catch (e, s) {
      _log.e('[verifyPayment] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectServer);
    }
  }
}
