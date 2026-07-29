/// Phí ship xem trước cho cả 3 tuỳ chọn giao hàng, tính theo khoảng cách
/// thật từ chi nhánh tới địa chỉ đang chọn — lấy từ
/// `GET /api/delivery-fee/preview`.
class DeliveryFeePreviewModel {
  final double priority;
  final double standard;
  final double saving;

  const DeliveryFeePreviewModel({
    required this.priority,
    required this.standard,
    required this.saving,
  });

  factory DeliveryFeePreviewModel.fromJson(Map<String, dynamic> json) {
    return DeliveryFeePreviewModel(
      priority: (json['priority'] as num? ?? 0).toDouble(),
      standard: (json['standard'] as num? ?? 0).toDouble(),
      saving: (json['saving'] as num? ?? 0).toDouble(),
    );
  }

  double feeFor(String deliveryOptionId) {
    switch (deliveryOptionId) {
      case 'priority':
        return priority;
      case 'saving':
        return saving;
      default:
        return standard;
    }
  }
}
