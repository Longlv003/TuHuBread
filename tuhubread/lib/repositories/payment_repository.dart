import '../core/result.dart';
import '../models/order_result.model.dart';
import '../models/payment_verify_result.model.dart';

/// Abstract repository cho chức năng thanh toán VNPay.
abstract class PaymentRepository {
  /// Tạo payment URL từ giỏ hàng hiện tại.
  /// Backend validate server-side, snapshot vào PaymentSession rồi trả về URL.
  Future<Result<OrderResultModel>> createVnpayPayment({
    required String addressId,
    required String deliveryOption,
    String? voucherCode,
    String? note,
  });

  /// Verify kết quả giao dịch sau khi WebView đóng.
  /// Flutter gọi API này để lấy trạng thái session & danh sách order codes.
  Future<Result<PaymentVerifyResult>> verifyPayment({required String txnRef});
}
