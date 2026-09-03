import 'package:logger/logger.dart';
import '../core/result.dart';
import '../models/notification_list_result.model.dart';
import 'notification_repository.dart';
import '../services/api_service.dart';
import '../l10n/app_strings.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

class NotificationRepositoryImpl implements NotificationRepository {
  final ApiService apiService;

  const NotificationRepositoryImpl({required this.apiService});

  @override
  Future<Result<NotificationListResult>> fetchMyNotifications({int page = 1}) async {
    try {
      final res = await apiService.get(
        '/api/notifications',
        query: {'page': page},
      );
      if (res['data'] != null) {
        return Success(
          NotificationListResult.fromJson(res['data'] as Map<String, dynamic>),
        );
      }
      return Failure(res['msg'] ?? AppStrings.current.errorLoadNotifications);
    } catch (e, s) {
      _log.e('[fetchMyNotifications] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectLoadNotifications);
    }
  }

  @override
  Future<Result<int>> fetchUnreadCount() async {
    try {
      final res = await apiService.get('/api/notifications/unread-count');
      if (res['data'] != null) {
        final count = (res['data'] as Map<String, dynamic>)['count'] as num? ?? 0;
        return Success(count.toInt());
      }
      return Failure(res['msg'] ?? AppStrings.current.errorLoadUnreadCount);
    } catch (e, s) {
      _log.e('[fetchUnreadCount] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectServer);
    }
  }

  @override
  Future<Result<bool>> markAsRead(String id) async {
    try {
      final res = await apiService.request(
        '/api/notifications/$id/read',
        method: 'PATCH',
      );
      if (res['data'] != null || res['msg'] == 'OK') {
        return const Success(true);
      }
      return Failure(res['msg'] ?? AppStrings.current.errorMarkRead);
    } catch (e, s) {
      _log.e('[markAsRead] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectServer);
    }
  }

  @override
  Future<Result<bool>> markAllAsRead() async {
    try {
      final res = await apiService.request(
        '/api/notifications/read-all',
        method: 'PATCH',
      );
      if (res['msg'] == 'OK' || res['data'] != null) {
        return const Success(true);
      }
      return Failure(res['msg'] ?? AppStrings.current.errorMarkAllRead);
    } catch (e, s) {
      _log.e('[markAllAsRead] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectServer);
    }
  }

  @override
  Future<Result<bool>> deleteNotification(String id) async {
    try {
      final res = await apiService.delete('/api/notifications/$id');
      if (res['data'] != null) {
        return const Success(true);
      }
      return Failure(res['msg'] ?? AppStrings.current.errorDeleteNotification);
    } catch (e, s) {
      _log.e('[deleteNotification] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectServer);
    }
  }

  @override
  Future<Result<bool>> deleteAllNotifications() async {
    try {
      final res = await apiService.delete('/api/notifications');
      if (res['data'] != null) {
        return const Success(true);
      }
      return Failure(res['msg'] ?? AppStrings.current.errorDeleteAllNotifications);
    } catch (e, s) {
      _log.e('[deleteAllNotifications] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectServer);
    }
  }

  @override
  Future<Result<bool>> registerDevice({
    required String fcmToken,
    required String platform,
    String? deviceId,
    String? deviceName,
  }) async {
    try {
      final res = await apiService.post('/api/notifications/device-token', {
        'token': fcmToken,
        'platform': platform,
      });
      if (res['success'] == true) {
        return const Success(true);
      }
      return Failure(res['msg'] ?? AppStrings.current.errorRegisterNotifications);
    } catch (e, s) {
      _log.e('[registerDevice] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectServer);
    }
  }

  @override
  Future<Result<bool>> unregisterDevice(String fcmToken) async {
    try {
      final res = await apiService.request(
        '/api/notifications/device-token',
        method: 'DELETE',
        data: {'token': fcmToken},
      );
      if (res['success'] == true) {
        return const Success(true);
      }
      return Failure(res['msg'] ?? AppStrings.current.errorUnregisterNotifications);
    } catch (e, s) {
      _log.e('[unregisterDevice] Failed', error: e, stackTrace: s);
      return Failure(AppStrings.current.errorConnectServer);
    }
  }

  @override
  Future<Result<void>> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    final res = await registerDevice(fcmToken: token, platform: platform);
    if (res is Success<bool>) {
      return const Success(null);
    }
    return Failure((res as Failure).message);
  }

  @override
  Future<Result<void>> deactivateDeviceToken({
    required String token,
  }) async {
    final res = await unregisterDevice(token);
    if (res is Success<bool>) {
      return const Success(null);
    }
    return Failure((res as Failure).message);
  }
}
