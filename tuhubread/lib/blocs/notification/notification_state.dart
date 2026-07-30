import '../../models/notification_item.model.dart';

abstract class NotificationState {
  const NotificationState();
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<NotificationItemModel> items;
  final int unreadCount;
  final Map<NotificationType, int> unreadByType;
  final int page;
  final int totalPages;

  const NotificationLoaded({
    required this.items,
    required this.unreadCount,
    required this.unreadByType,
    required this.page,
    required this.totalPages,
  });

  NotificationLoaded copyWith({
    List<NotificationItemModel>? items,
    int? unreadCount,
    Map<NotificationType, int>? unreadByType,
    int? page,
    int? totalPages,
  }) {
    return NotificationLoaded(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      unreadByType: unreadByType ?? this.unreadByType,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class NotificationFailure extends NotificationState {
  final String error;
  const NotificationFailure(this.error);
}
