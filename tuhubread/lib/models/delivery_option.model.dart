/// Tùy chọn tốc độ giao hàng, khớp với `delivery_option` enum ở backend
/// (be/models/order.model.js) và bảng phí `DELIVERY_FEES` trong
/// be/controllers/order.controller.js.
class DeliveryOptionModel {
  final String id;
  final String label;
  final String description;
  final double fee;

  const DeliveryOptionModel({
    required this.id,
    required this.label,
    required this.description,
    required this.fee,
  });

  static const priority = DeliveryOptionModel(
    id: 'priority',
    label: 'Ưu tiên',
    description: 'Giao nhanh nhất, trong vòng 30 phút',
    fee: 25000,
  );

  static const standard = DeliveryOptionModel(
    id: 'standard',
    label: 'Nhanh',
    description: 'Giao trong vòng 1 giờ',
    fee: 15000,
  );

  static const saving = DeliveryOptionModel(
    id: 'saving',
    label: 'Tiết kiệm',
    description: 'Giao trong 2-3 giờ, miễn phí ship',
    fee: 0,
  );

  static const all = [priority, standard, saving];
}
