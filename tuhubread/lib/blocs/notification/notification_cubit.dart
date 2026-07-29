import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/result.dart';
import '../../models/notification.model.dart';
import '../../repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository repository;

  NotificationCubit({required this.repository}) : super(NotificationInitial());

  Future<void> loadNotifications() async {
    emit(NotificationLoading());
    final result = await repository.getNotifications(page: 1, limit: 100);
    final countResult = await repository.getUnreadCount();

    switch (result) {
      case Success(data: final notifications):
        final unreadCount = switch (countResult) {
          Success(data: final count) => count,
          Failure() => 0,
        };
        emit(NotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ));
      case Failure(message: final errorMsg):
        emit(NotificationFailure(errorMsg));
    }
  }

  Future<void> markAsRead(String id) async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      // 1. Cập nhật UI ngay lập tức (Optimistic Update)
      final updatedList = currentState.notifications.map((n) {
        if (n.id == id) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            sentAt: n.sentAt,
            orderId: n.orderId,
          );
        }
        return n;
      }).toList();
      
      final wasUnread = currentState.notifications.any((n) => n.id == id && !n.isRead);
      final newUnreadCount = wasUnread ? max(0, currentState.unreadCount - 1) : currentState.unreadCount;
      
      emit(NotificationLoaded(
        notifications: updatedList,
        unreadCount: newUnreadCount,
      ));

      // 2. Gọi API ngầm ở background
      final res = await repository.markAsRead(id);
      if (res is Failure) {
        // Log lỗi hoặc xử lý nếu API thất bại
        print('[NotificationCubit] Failed to mark notification $id as read: ${res.message}');
      }
    }
  }

  Future<void> markAllAsRead() async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      // 1. Cập nhật UI ngay lập tức (Optimistic Update)
      final updatedList = currentState.notifications.map((n) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          sentAt: n.sentAt,
          orderId: n.orderId,
        );
      }).toList();
      
      emit(NotificationLoaded(
        notifications: updatedList,
        unreadCount: 0,
      ));

      // 2. Gọi API ngầm ở background
      final res = await repository.markAllAsRead();
      if (res is Failure) {
        // Log lỗi nếu API thất bại
        print('[NotificationCubit] Failed to mark all notifications as read: ${res.message}');
      }
    }
  }
}
