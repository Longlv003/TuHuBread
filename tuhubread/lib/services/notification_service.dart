import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../blocs/notification/notification_cubit.dart';
import '../di.dart';
import '../routes/routes.dart';
import '../repositories/notification_repository.dart';

class NotificationService {
  final NotificationRepository repository;
  final _messaging = FirebaseMessaging.instance;
  final _log = Logger();

  NotificationService({required this.repository});

  Future<void> init() async {
    // 1. Request Permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    _log.i('[NotificationService] User granted permission: ${settings.authorizationStatus}');

    // 2. Configure Foreground Notification Presentation
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Listen to Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _log.i('[NotificationService] Foreground message received: ${message.notification?.title}');
      
      final title = message.notification?.title ?? 'Thông báo mới';
      final body = message.notification?.body ?? '';
      final data = message.data;
      final orderId = data['orderId'] as String?;

      // Auto-reload notifications list & badge count
      try {
        getIt<NotificationCubit>().loadNotifications();
      } catch (e) {
        _log.e('[NotificationService] Failed to reload notifications on message: $e');
      }

      // Display custom foreground snackbar using GetX
      Get.snackbar(
        title,
        body,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFFFF0E0),
        colorText: const Color(0xFF2C3E50),
        duration: const Duration(seconds: 4),
        onTap: (_) {
          if (orderId != null && orderId.isNotEmpty) {
            Get.toNamed(Routes.trackOrderPage, arguments: orderId);
          }
        },
      );
    });

    // 4. Listen to user clicking on notification (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _log.i('[NotificationService] Message opened app: ${message.messageId}');
      try {
        getIt<NotificationCubit>().loadNotifications();
      } catch (_) {}
      _handleNotificationClick(message);
    });

    // 5. Check if the app was opened from a terminated state via a notification click
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _log.i('[NotificationService] Initial message found: ${initialMessage.messageId}');
      _handleNotificationClick(initialMessage);
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    final data = message.data;
    final orderId = data['orderId'] as String?;
    if (orderId != null && orderId.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.toNamed(Routes.trackOrderPage, arguments: orderId);
      });
    }
  }

  Future<void> registerDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _log.i('[NotificationService] Registering device token: $token');
        final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
        await repository.registerDeviceToken(
          token: token,
          platform: platform,
        );
      }
    } catch (e) {
      _log.e('[NotificationService] Failed to register device token: $e');
    }
  }

  Future<void> deactivateDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _log.i('[NotificationService] Deactivating device token: $token');
        await repository.deactivateDeviceToken(token: token);
      }
    } catch (e) {
      _log.e('[NotificationService] Failed to deactivate device token: $e');
    }
  }
}
