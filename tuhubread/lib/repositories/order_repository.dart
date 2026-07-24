import '../core/result.dart';
import '../models/cart_item.model.dart';
import '../models/order_result.model.dart';

abstract class OrderRepository {
  Future<Result<OrderResultModel>> createOrder({
    required String addressId,
    required String deliveryOption,
    required String paymentMethod,
    required List<CartItemModel> items,
    String? note,
    String? voucherCode,
  });

  Future<Result<OrderResultModel>> createVnpayPayment({
    required String addressId,
    required String deliveryOption,
    String? note,
    String? voucherCode,
  });
}
