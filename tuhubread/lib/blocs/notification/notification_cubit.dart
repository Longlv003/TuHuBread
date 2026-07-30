import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/result.dart';
import '../../models/notification_item.model.dart';
import '../../models/notification_list_result.model.dart';
import '../../repositories/notification_repository.dart';
import 'notification_state.dart';

/// Singleton toàn app (giống CartCubit) — để badge số thông báo chưa đọc ở
/// header luôn khớp bất kể đang ở màn nào, không phải load lại mỗi lần vào
/// trang Thông báo.
class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository repository;

  NotificationCubit({required this.repository}) : super(const NotificationInitial());

  Future<void> loadNotifications({int page = 1}) async {
    emit(const NotificationLoading());
    final result = await repository.fetchMyNotifications(page: page);
    if (result is Success<NotificationListResult>) {
      emit(NotificationLoaded(
        items: result.data.notifications,
        unreadCount: result.data.unreadCount,
        unreadByType: result.data.unreadByType,
        page: result.data.page,
        totalPages: result.data.totalPages,
      ));
    } else if (result is Failure<NotificationListResult>) {
      emit(NotificationFailure(result.message));
    }
  }

  /// Chỉ cập nhật số badge — gọi lúc mở app / khi có FCM đến lúc app đang mở,
  /// không cần tải lại cả danh sách.
  Future<void> refreshUnreadCount() async {
    final result = await repository.fetchUnreadCount();
    if (result is Success<int>) {
      final current = state;
      if (current is NotificationLoaded) {
        emit(current.copyWith(unreadCount: result.data));
      } else {
        emit(NotificationLoaded(
          items: const [],
          unreadCount: result.data,
          unreadByType: const {},
          page: 1,
          totalPages: 1,
        ));
      }
    }
  }

  Map<NotificationType, int> _decrement(Map<NotificationType, int> byType, NotificationType type) {
    final next = Map<NotificationType, int>.from(byType);
    next[type] = ((next[type] ?? 0) - 1).clamp(0, 1 << 30);
    return next;
  }

  Future<void> markAsRead(String id) async {
    final current = state;
    if (current is! NotificationLoaded) return;

    final matches = current.items.where((n) => n.id == id);
    if (matches.isEmpty || matches.first.isRead) return;

    // Optimistic update — cập nhật UI ngay, không chờ server.
    emit(current.copyWith(
      items: current.items.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
      unreadCount: (current.unreadCount - 1).clamp(0, 1 << 30),
      unreadByType: _decrement(current.unreadByType, matches.first.type),
    ));

    final result = await repository.markAsRead(id);
    if (result is Failure<bool>) {
      // Rollback nếu server từ chối.
      emit(current);
    }
  }

  Future<void> markAllAsRead() async {
    final current = state;
    if (current is! NotificationLoaded || current.unreadCount == 0) return;

    emit(current.copyWith(
      items: current.items.map((n) => n.copyWith(isRead: true)).toList(),
      unreadCount: 0,
      unreadByType: const {
        NotificationType.order: 0,
        NotificationType.voucher: 0,
        NotificationType.system: 0,
      },
    ));

    final result = await repository.markAllAsRead();
    if (result is Failure<bool>) {
      emit(current);
    }
  }

  Future<void> deleteNotification(String id) async {
    final current = state;
    if (current is! NotificationLoaded) return;

    final matches = current.items.where((n) => n.id == id);
    if (matches.isEmpty) return;
    final target = matches.first;

    // Optimistic update — xoá khỏi UI ngay, không chờ server.
    emit(current.copyWith(
      items: current.items.where((n) => n.id != id).toList(),
      unreadCount: target.isRead ? current.unreadCount : (current.unreadCount - 1).clamp(0, 1 << 30),
      unreadByType: target.isRead ? current.unreadByType : _decrement(current.unreadByType, target.type),
    ));

    final result = await repository.deleteNotification(id);
    if (result is Failure<bool>) {
      // Rollback nếu server từ chối.
      emit(current);
    }
  }

  Future<void> deleteAllNotifications() async {
    final current = state;
    if (current is! NotificationLoaded || current.items.isEmpty) return;

    emit(current.copyWith(
      items: const [],
      unreadCount: 0,
      unreadByType: const {
        NotificationType.order: 0,
        NotificationType.voucher: 0,
        NotificationType.system: 0,
      },
    ));

    final result = await repository.deleteAllNotifications();
    if (result is Failure<bool>) {
      emit(current);
    }
  }

  /// Xoá sạch state — gọi lúc đăng xuất để không giữ badge/dữ liệu của tài
  /// khoản vừa thoát cho tới khi tài khoản khác đăng nhập.
  void reset() => emit(const NotificationInitial());
}
