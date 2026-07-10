enum NotificationType { order, promotion, system }

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime time;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });
}

/// Nguồn dữ liệu thông báo mẫu (chưa nối API) — dùng chung giữa chuông
/// thông báo ở header và màn danh sách thông báo để badge số lượng
/// chưa đọc luôn khớp nhau.
class MockNotifications {
  static final List<NotificationItem> items = [
    NotificationItem(
      id: '1',
      type: NotificationType.order,
      title: 'Đơn hàng đã được xác nhận',
      message: 'Đơn hàng #DH00123 của bạn đã được cửa hàng xác nhận và đang chuẩn bị.',
      time: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    NotificationItem(
      id: '2',
      type: NotificationType.promotion,
      title: 'Voucher giảm 20% dành cho bạn',
      message: 'Nhập mã BREAD20 để được giảm 20% cho đơn hàng tiếp theo, áp dụng đến hết ngày.',
      time: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationItem(
      id: '3',
      type: NotificationType.order,
      title: 'Đơn hàng đang được giao',
      message: 'Shipper đang trên đường giao đơn hàng #DH00120 tới bạn.',
      time: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      type: NotificationType.system,
      title: 'Cập nhật chính sách bảo mật',
      message: 'TuHuBread vừa cập nhật chính sách bảo mật. Vui lòng xem chi tiết trong phần Cài đặt.',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      type: NotificationType.promotion,
      title: 'Flash Sale bánh mì que chỉ từ 10.000đ',
      message: 'Săn ngay bánh mì que giá sốc trong khung giờ vàng 11h - 13h hôm nay.',
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    NotificationItem(
      id: '6',
      type: NotificationType.order,
      title: 'Đơn hàng đã hoàn thành',
      message: 'Đơn hàng #DH00115 đã giao thành công. Cảm ơn bạn đã ủng hộ TuHuBread!',
      time: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  static int get unreadCount => items.where((e) => !e.isRead).length;

  static void markAllAsRead() {
    for (final item in items) {
      item.isRead = true;
    }
  }
}
