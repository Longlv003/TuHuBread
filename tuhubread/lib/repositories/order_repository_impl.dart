import 'package:logger/logger.dart';

import '../core/result.dart';
import '../models/cart_item.model.dart';
import '../models/order_result.model.dart';
import '../services/api_service.dart';
import 'order_repository.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

class OrderRepositoryImpl implements OrderRepository {
  final ApiService apiService;

  const OrderRepositoryImpl({required this.apiService});

  @override
  Future<Result<OrderResultModel>> createOrder({
    required String addressId,
    required String deliveryOption,
    required String paymentMethod,
    required List<CartItemModel> items,
    String? note,
    String? voucherCode,
  }) async {
    try {
      final res = await apiService.post('/api/orders', {
        'address_id': addressId,
        'delivery_option': deliveryOption,
        'payment_method': paymentMethod,
        'note': note,
        'voucher_code': voucherCode,
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
      return Failure(res['msg'] ?? 'Không thể đặt hàng');
    } catch (e, s) {
      _log.e('[createOrder] Failed', error: e, stackTrace: s);
      return const Failure('Không thể kết nối đến máy chủ để đặt hàng');
    }
  }

  @override
  Future<Result<OrderResultModel>> createVnpayPayment({
    required String addressId,
    required String deliveryOption,
    String? note,
    String? voucherCode,
  }) async {
    try {
      final res = await apiService.post('/api/payments/vnpay', {
        'address_id': addressId,
        'delivery_option': deliveryOption,
        'note': note,
        'voucher_code': voucherCode,
      });

      if (res['data'] != null) {
        return Success(
          OrderResultModel.fromJson(res['data'] as Map<String, dynamic>),
        );
      }
      return Failure(res['msg'] ?? 'Không thể tạo link thanh toán VNPay');
    } catch (e, s) {
      _log.e('[createVnpayPayment] Failed', error: e, stackTrace: s);
      return const Failure('Không thể kết nối đến máy chủ để thanh toán');
    }
  }
}
