import 'package:logger/logger.dart';
import '../core/result.dart';
import '../models/notification.model.dart';
import '../services/api_service.dart';
import 'notification_repository.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

class NotificationRepositoryImpl implements NotificationRepository {
  final ApiService apiService;

  const NotificationRepositoryImpl({required this.apiService});

  @override
  Future<Result<void>> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      final res = await apiService.post('/api/notifications/device-token', {
        'token': token,
        'platform': platform,
      });

      if (res['data'] != null || res['msg'] == 'OK') {
        return const Success(null);
      }
      return Failure(res['msg'] ?? 'Không thể đăng ký token thiết bị');
    } catch (e, s) {
      _log.e('[registerDeviceToken] Failed', error: e, stackTrace: s);
      return const Failure('Lỗi kết nối máy chủ khi đăng ký token');
    }
  }

  @override
  Future<Result<void>> deactivateDeviceToken({
    required String token,
  }) async {
    try {
      final res = await apiService.request(
        '/api/notifications/device-token',
        method: 'DELETE',
        data: {'token': token},
      );

      if (res['msg'] == 'OK' || res['data'] != null) {
        return const Success(null);
      }
      return Failure(res['msg'] ?? 'Không thể hủy đăng ký token thiết bị');
    } catch (e, s) {
      _log.e('[deactivateDeviceToken] Failed', error: e, stackTrace: s);
      return const Failure('Lỗi kết nối máy chủ khi hủy đăng ký token');
    }
  }

  @override
  Future<Result<List<NotificationModel>>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await apiService.get(
        '/api/notifications',
        query: {'page': page, 'limit': limit},
      );

      if (res['data'] != null) {
        final notificationsData = res['data']['notifications'] as List<dynamic>? ?? [];
        final list = notificationsData
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return Success(list);
      }
      return Failure(res['msg'] ?? 'Không thể tải danh sách thông báo');
    } catch (e, s) {
      _log.e('[getNotifications] Failed', error: e, stackTrace: s);
      return const Failure('Lỗi kết nối máy chủ khi tải thông báo');
    }
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    try {
      final res = await apiService.get('/api/notifications/unread-count');
      if (res['data'] != null) {
        final count = res['data']['count'] as int? ?? 0;
        return Success(count);
      }
      return Failure(res['msg'] ?? 'Không thể lấy số lượng thông báo chưa đọc');
    } catch (e, s) {
      _log.e('[getUnreadCount] Failed', error: e, stackTrace: s);
      return const Failure('Lỗi kết nối máy chủ');
    }
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      final res = await apiService.request(
        '/api/notifications/$notificationId/read',
        method: 'PATCH',
      );
      if (res['data'] != null || res['msg'] == 'OK') {
        return const Success(null);
      }
      return Failure(res['msg'] ?? 'Không thể đánh dấu đã đọc');
    } catch (e, s) {
      _log.e('[markAsRead] Failed', error: e, stackTrace: s);
      return const Failure('Lỗi kết nối máy chủ');
    }
  }

  @override
  Future<Result<void>> markAllAsRead() async {
    try {
      final res = await apiService.request(
        '/api/notifications/read-all',
        method: 'PATCH',
      );
      if (res['msg'] == 'OK' || res['data'] != null) {
        return const Success(null);
      }
      return Failure(res['msg'] ?? 'Không thể đánh dấu tất cả đã đọc');
    } catch (e, s) {
      _log.e('[markAllAsRead] Failed', error: e, stackTrace: s);
      return const Failure('Lỗi kết nối máy chủ');
    }
  }
}
