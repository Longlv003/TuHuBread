/// Kết quả tạo đơn hàng — response của POST /api/orders.
/// Giỏ hàng có thể chứa sản phẩm của nhiều shop khác nhau, backend tách
/// thành nhiều đơn (mỗi shop 1 đơn) nên trả về danh sách mã đơn.
class OrderResultModel {
  final List<String> orderCodes;
  final double totalAmount;

  const OrderResultModel({required this.orderCodes, required this.totalAmount});

  factory OrderResultModel.fromJson(Map<String, dynamic> json) {
    final orders = (json['orders'] as List? ?? [])
        .map((e) => (e as Map<String, dynamic>)['order_code'] as String)
        .toList();
    return OrderResultModel(
      orderCodes: orders,
      totalAmount: (json['total_amount'] as num? ?? 0).toDouble(),
    );
  }
}
