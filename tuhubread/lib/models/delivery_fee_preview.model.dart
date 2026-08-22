/// Phí ship xem trước cho cả 3 tuỳ chọn giao hàng, tính theo khoảng cách
/// thật từ chi nhánh tới địa chỉ đang chọn — lấy từ
/// `GET /api/delivery-fee/preview`.
class DeliveryFeePreviewModel {
  final double priority;
  final double standard;
  final double saving;

  /// Khoảng cách shop -> địa chỉ (km) — null nếu 1 trong 2 phía chưa có toạ độ.
  final double? distanceKm;

  /// Lý do không giao được tới địa chỉ này (null = giao được):
  /// "out_of_range" (quá xa) hoặc "missing_address_location" (địa chỉ chưa
  /// ghim vị trí trên bản đồ nên không kiểm tra được).
  final String? blockReason;

  /// Thông báo tiếng Việt tương ứng, hiển thị thẳng cho khách.
  final String? blockMessage;

  final double maxDeliveryKm;

  /// Có bị chặn đặt hàng với địa chỉ này không.
  bool get isBlocked => blockReason != null;

  const DeliveryFeePreviewModel({
    required this.priority,
    required this.standard,
    required this.saving,
    this.distanceKm,
    this.blockReason,
    this.blockMessage,
    this.maxDeliveryKm = 30,
  });

  factory DeliveryFeePreviewModel.fromJson(Map<String, dynamic> json) {
    return DeliveryFeePreviewModel(
      priority: (json['priority'] as num? ?? 0).toDouble(),
      standard: (json['standard'] as num? ?? 0).toDouble(),
      saving: (json['saving'] as num? ?? 0).toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      blockReason: json['block_reason'] as String?,
      blockMessage: json['block_message'] as String?,
      maxDeliveryKm: (json['max_delivery_km'] as num? ?? 30).toDouble(),
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
