enum NotificationType { order, voucher, system }

NotificationType _typeFromString(String? value) {
  switch (value) {
    case 'voucher':
      return NotificationType.voucher;
    case 'system':
      return NotificationType.system;
    default:
      return NotificationType.order;
  }
}

/// 1 thông báo lấy từ server.
class NotificationItemModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;
  final Map<String, dynamic>? data;

  const NotificationItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    this.data,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['_id'] as String,
      type: _typeFromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      time: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  NotificationItemModel copyWith({bool? isRead}) {
    return NotificationItemModel(
      id: id,
      type: type,
      title: title,
      body: body,
      time: time,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }
}
