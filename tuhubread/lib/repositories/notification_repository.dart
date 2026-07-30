import '../core/result.dart';
import '../models/notification_list_result.model.dart';

abstract class NotificationRepository {
  Future<Result<NotificationListResult>> fetchMyNotifications({int page = 1});

  Future<Result<int>> fetchUnreadCount();

  Future<Result<bool>> markAsRead(String id);

  Future<Result<bool>> markAllAsRead();

  Future<Result<bool>> deleteNotification(String id);

  Future<Result<bool>> deleteAllNotifications();

  Future<Result<bool>> registerDevice({
    required String fcmToken,
    required String platform,
    String? deviceId,
    String? deviceName,
  });

  Future<Result<bool>> unregisterDevice(String fcmToken);
}
