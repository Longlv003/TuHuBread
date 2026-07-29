import '../core/result.dart';
import '../models/cart_item.model.dart';
import '../models/delivery_fee_preview.model.dart';
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

  /// Xem trước phí ship theo khoảng cách thật cho cả 3 tuỳ chọn giao hàng,
  /// dùng ở màn Thanh toán khi khách đổi địa chỉ — không tạo đơn hàng.
  Future<Result<DeliveryFeePreviewModel>> previewDeliveryFee({
    required String shopId,
    required String addressId,
  });
}
