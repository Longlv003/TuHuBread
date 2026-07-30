import 'notification_item.model.dart';

Map<NotificationType, int> _unreadByTypeFromJson(Map<String, dynamic>? json) {
  return {
    NotificationType.order: (json?['order'] as num? ?? 0).toInt(),
    NotificationType.voucher: (json?['voucher'] as num? ?? 0).toInt(),
    NotificationType.system: (json?['system'] as num? ?? 0).toInt(),
  };
}

/// Kết quả trả về từ `GET /api/notifications` — danh sách 1 trang kèm tổng
/// số & số chưa đọc, dùng để cập nhật badge chuông thông báo.
class NotificationListResult {
  final List<NotificationItemModel> notifications;
  final int total;
  final int unreadCount;
  final Map<NotificationType, int> unreadByType;
  final int page;
  final int totalPages;

  const NotificationListResult({
    required this.notifications,
    required this.total,
    required this.unreadCount,
    required this.unreadByType,
    required this.page,
    required this.totalPages,
  });

  factory NotificationListResult.fromJson(Map<String, dynamic> json) {
    final list = (json['notifications'] as List? ?? [])
        .map((e) => NotificationItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificationListResult(
      notifications: list,
      total: (json['total'] as num? ?? 0).toInt(),
      unreadCount: (json['unreadCount'] as num? ?? 0).toInt(),
      unreadByType: _unreadByTypeFromJson(json['unreadByType'] as Map<String, dynamic>?),
      page: (json['page'] as num? ?? 1).toInt(),
      totalPages: (json['totalPages'] as num? ?? 1).toInt(),
    );
  }
}
