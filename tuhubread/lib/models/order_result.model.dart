/// Kết quả tạo đơn hàng — response của POST /api/orders, POST
/// /api/payments/sepay, hoặc POST /api/payments/vnpay.
/// Giỏ hàng có thể chứa sản phẩm của nhiều shop khác nhau, backend tách
/// thành nhiều đơn (mỗi shop 1 đơn) nên trả về danh sách mã đơn.
class OrderResultModel {
  final List<String> orderCodes;
  final double totalAmount;

  /// URL cổng thanh toán SePay để POST [checkoutFields] tới.
  final String? checkoutUrl;

  /// Các field cần gửi kèm (đã ký sẵn HMAC-SHA256 bởi backend) khi POST tới
  /// [checkoutUrl] — SePay dùng biểu mẫu POST, khác VNPay chỉ cần redirect
  /// GET tới 1 URL duy nhất.
  final Map<String, dynamic>? checkoutFields;

  /// URL thanh toán VNPay — chỉ cần redirect GET, không cần POST biểu mẫu.
  final String? paymentUrl;

  /// Mã giao dịch (order_invoice_number / vnp_TxnRef) — dùng để gọi verify
  /// sau khi WebView đóng.
  final String? txnRef;

  const OrderResultModel({
    required this.orderCodes,
    required this.totalAmount,
    this.checkoutUrl,
    this.checkoutFields,
    this.paymentUrl,
    this.txnRef,
  });

  factory OrderResultModel.fromJson(Map<String, dynamic> json) {
    final orders = (json['orders'] as List? ?? [])
        .map((e) => (e as Map<String, dynamic>)['order_code'] as String)
        .toList();
    return OrderResultModel(
      orderCodes: orders,
      totalAmount: (json['total_amount'] as num? ?? 0).toDouble(),
      checkoutUrl: json['checkout_url'] as String?,
      checkoutFields: json['checkout_fields'] as Map<String, dynamic>?,
      paymentUrl: json['payment_url'] as String?,
      txnRef: json['txn_ref'] as String?,
    );
  }
}
