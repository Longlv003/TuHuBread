/// Tùy chọn tốc độ giao hàng, khớp với `delivery_option` enum ở backend
/// (be/models/order.model.js) và bảng phí `DELIVERY_FEES` trong
/// be/controllers/order.controller.js.
class DeliveryOptionModel {
  final String id;
  final double fee;

  const DeliveryOptionModel({required this.id, required this.fee});

  /// Cùng tuỳ chọn nhưng với mức phí lấy từ server (phí thật phụ thuộc khoảng
  /// cách giao hàng, chỉ biết sau khi người dùng chọn địa chỉ).
  DeliveryOptionModel copyWithFee(double newFee) =>
      DeliveryOptionModel(id: id, fee: newFee);

  /// Nhãn và mô tả hiển thị KHÔNG nằm ở đây: chúng được tra theo [id] từ file
  /// dịch trong CheckoutDeliveryOptionTile, nên đổi ngôn ngữ là đổi theo.
  static const priority = DeliveryOptionModel(id: 'priority', fee: 25000);

  static const standard = DeliveryOptionModel(id: 'standard', fee: 15000);

  static const saving = DeliveryOptionModel(id: 'saving', fee: 0);

  static const all = [priority, standard, saving];
}
