import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';

import '../core/result.dart';
import '../repositories/notification_repository.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

/// Đăng ký thiết bị nhận FCM push + lắng nghe thông báo lúc app đang mở
/// (foreground). Thông báo lúc app chạy nền/tắt hẳn do hệ điều hành tự hiển
/// thị (mặc định của FCM khi payload có field "notification"), không cần
/// xử lý thêm ở đây.
class PushNotificationService {
  final NotificationRepository repository;
  String? _registeredToken;

  PushNotificationService({required this.repository});

  String get _platform {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'web';
  }

  /// Xin quyền (iOS cần xin tường minh), lấy FCM token, gửi lên server, và
  /// tự gửi lại mỗi khi token đổi (Firebase thỉnh thoảng tự cấp token mới).
  /// Gọi sau khi đăng nhập thành công. Không throw — lỗi chỉ log, không làm
  /// hỏng luồng đăng nhập.
  Future<void> registerDevice() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _log.w('[registerDevice] Người dùng từ chối quyền thông báo');
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _sendTokenToServer(token);

      FirebaseMessaging.instance.onTokenRefresh.listen(_sendTokenToServer);
    } catch (e, s) {
      _log.e('[registerDevice] Failed', error: e, stackTrace: s);
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    _registeredToken = token;
    final result = await repository.registerDevice(
      fcmToken: token,
      platform: _platform,
    );
    if (result is Failure<bool>) {
      _log.e('[registerDevice] Server rejected token: ${result.message}');
    }
  }

  /// Gọi lúc đăng xuất — ngừng gửi push tới thiết bị này cho tài khoản vừa
  /// thoát ra (không xoá token khỏi Firebase, chỉ đánh dấu ngưng ở server).
  Future<void> unregisterCurrentDevice() async {
    try {
      final token = _registeredToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await repository.unregisterDevice(token);
    } catch (e, s) {
      _log.e('[unregisterCurrentDevice] Failed', error: e, stackTrace: s);
    }
  }

  /// Lắng nghe FCM lúc app đang mở (foreground) — hệ điều hành sẽ KHÔNG tự
  /// hiện banner trong trường hợp này, nên [onForegroundMessage] dùng để
  /// cập nhật badge/toast trong app.
  void listenForeground(void Function()? onForegroundMessage) {
    FirebaseMessaging.onMessage.listen((message) {
      _log.i('[FCM foreground] ${message.notification?.title}: ${message.notification?.body}');
      onForegroundMessage?.call();
    });
  }
}
