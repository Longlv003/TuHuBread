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

  Map<NotificationType, int> _increment(Map<NotificationType, int> byType, NotificationType type) {
    final next = Map<NotificationType, int>.from(byType);
    next[type] = (next[type] ?? 0) + 1;
    return next;
  }

  Future<void> markAsRead(String id) async {
    final current = state;
    if (current is! NotificationLoaded) return;

    final matches = current.items.where((n) => n.id == id);
    if (matches.isEmpty || matches.first.isRead) return;
    final type = matches.first.type;

    // Optimistic update — cập nhật UI ngay, không chờ server.
    emit(current.copyWith(
      items: current.items.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
      unreadCount: (current.unreadCount - 1).clamp(0, 1 << 30),
      unreadByType: _decrement(current.unreadByType, type),
    ));

    final result = await repository.markAsRead(id);
    if (result is Failure<bool>) {
      // Rollback trên state MỚI NHẤT (không phải snapshot cũ) — chỉ hoàn tác
      // đúng item này, tránh xoá mất các thay đổi khác xảy ra song song trong
      // lúc chờ request.
      final latest = state;
      if (latest is NotificationLoaded && latest.items.any((n) => n.id == id && n.isRead)) {
        emit(latest.copyWith(
          items: latest.items.map((n) => n.id == id ? n.copyWith(isRead: false) : n).toList(),
          unreadCount: latest.unreadCount + 1,
          unreadByType: _increment(latest.unreadByType, type),
        ));
      }
    }
  }

  Future<void> markAllAsRead() async {
    final current = state;
    if (current is! NotificationLoaded || current.unreadCount == 0) return;

    final revertedIds = current.items.where((n) => !n.isRead).map((n) => n.id).toSet();
    final revertedCount = revertedIds.length;
    final revertedByType = Map<NotificationType, int>.from(current.unreadByType);

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
      final latest = state;
      if (latest is NotificationLoaded) {
        emit(latest.copyWith(
          items: latest.items
              .map((n) => revertedIds.contains(n.id) ? n.copyWith(isRead: false) : n)
              .toList(),
          unreadCount: latest.unreadCount + revertedCount,
          unreadByType: {
            for (final type in NotificationType.values)
              type: (latest.unreadByType[type] ?? 0) + (revertedByType[type] ?? 0),
          },
        ));
      }
    }
  }

  Future<void> deleteNotification(String id) async {
    final current = state;
    if (current is! NotificationLoaded) return;

    final matches = current.items.where((n) => n.id == id);
    if (matches.isEmpty) return;
    final target = matches.first;
    final targetIndex = current.items.indexOf(target);

    // Optimistic update — xoá khỏi UI ngay, không chờ server.
    emit(current.copyWith(
      items: current.items.where((n) => n.id != id).toList(),
      unreadCount: target.isRead ? current.unreadCount : (current.unreadCount - 1).clamp(0, 1 << 30),
      unreadByType: target.isRead ? current.unreadByType : _decrement(current.unreadByType, target.type),
    ));

    final result = await repository.deleteNotification(id);
    if (result is Failure<bool>) {
      // Rollback trên state mới nhất: chèn lại đúng item đã xoá, không ghi đè
      // toàn bộ danh sách bằng snapshot cũ.
      final latest = state;
      if (latest is NotificationLoaded && !latest.items.any((n) => n.id == id)) {
        final restoredItems = List<NotificationItemModel>.from(latest.items);
        restoredItems.insert(targetIndex.clamp(0, restoredItems.length), target);
        emit(latest.copyWith(
          items: restoredItems,
          unreadCount: target.isRead ? latest.unreadCount : latest.unreadCount + 1,
          unreadByType: target.isRead ? latest.unreadByType : _increment(latest.unreadByType, target.type),
        ));
      }
    }
  }

  Future<void> deleteAllNotifications() async {
    final current = state;
    if (current is! NotificationLoaded || current.items.isEmpty) return;

    final previousItems = current.items;
    final previousUnreadCount = current.unreadCount;
    final previousUnreadByType = current.unreadByType;

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
      final latest = state;
      // Chỉ khôi phục nếu không có thông báo mới nào đến trong lúc chờ —
      // nếu có, giữ nguyên để không mất dữ liệu mới hơn snapshot cũ.
      if (latest is NotificationLoaded && latest.items.isEmpty) {
        emit(latest.copyWith(
          items: previousItems,
          unreadCount: previousUnreadCount,
          unreadByType: previousUnreadByType,
        ));
      }
    }
  }

  /// Xoá sạch state — gọi lúc đăng xuất để không giữ badge/dữ liệu của tài
  /// khoản vừa thoát cho tới khi tài khoản khác đăng nhập.
  void reset() => emit(const NotificationInitial());
}
