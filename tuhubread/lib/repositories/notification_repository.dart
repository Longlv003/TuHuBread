import '../core/result.dart';
import '../models/notification.model.dart';

abstract class NotificationRepository {
  Future<Result<void>> registerDeviceToken({
    required String token,
    required String platform,
  });

  Future<Result<void>> deactivateDeviceToken({
    required String token,
  });

  Future<Result<List<NotificationModel>>> getNotifications({
    int page = 1,
    int limit = 20,
  });

  Future<Result<int>> getUnreadCount();

  Future<Result<void>> markAsRead(String notificationId);

  Future<Result<void>> markAllAsRead();
}
