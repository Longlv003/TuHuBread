import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../blocs/notification/notification_cubit.dart';
import '../blocs/notification/notification_state.dart';
import '../di.dart';
import '../models/notification_item.model.dart';
import '../widgets/app_confirm_dialog.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotificationType? _filter;

  @override
  void initState() {
    super.initState();
    // Luôn tải lại danh sách mới nhất mỗi khi mở màn Thông báo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        getIt<NotificationCubit>().loadNotifications();
      }
    });
  }

  List<NotificationItemModel> _filtered(List<NotificationItemModel> items) {
    final sorted = List<NotificationItemModel>.from(items)
      ..sort((a, b) => b.time.compareTo(a.time));
    if (_filter == null) return sorted;
    return sorted.where((e) => e.type == _filter).toList();
  }

  String _formatTime(AppLocalizations l10n, DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return l10n.notificationsJustNow;
    if (diff.inMinutes < 60) return l10n.notificationsMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.notificationsHoursAgo(diff.inHours);
    return l10n.notificationsDaysAgo(diff.inDays);
  }

  Future<bool> _confirmDeleteOne(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      type: ConfirmDialogType.danger,
      title: l10n.notificationsDeleteConfirmTitle,
      description: l10n.notificationsDeleteConfirmMessage,
      confirmTitle: l10n.cartRemoveConfirmBtn,
      cancelTitle: l10n.cartCancel,
    );
    return confirmed == true;
  }

  Future<void> _confirmDeleteAll(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      type: ConfirmDialogType.danger,
      title: l10n.notificationsDeleteAllConfirmTitle,
      description: l10n.notificationsDeleteAllConfirmMessage,
      confirmTitle: l10n.notificationsDeleteAllTooltip,
      cancelTitle: l10n.cartCancel,
    );
    if (confirmed == true) {
      getIt<NotificationCubit>().deleteAllNotifications();
    }
  }

  ({IconData icon, Color color}) _styleFor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return (icon: Icons.receipt_long_rounded, color: const Color(0xFFE67E22));
      case NotificationType.voucher:
        return (icon: Icons.local_offer_rounded, color: const Color(0xFFE74C3C));
      case NotificationType.system:
        return (icon: Icons.campaign_rounded, color: const Color(0xFF2980B9));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<NotificationCubit, NotificationState>(
      bloc: getIt<NotificationCubit>(),
      builder: (context, state) {
        final items = state is NotificationLoaded ? state.items : <NotificationItemModel>[];
        final unreadCount = state is NotificationLoaded ? state.unreadCount : 0;
        final unreadByType = state is NotificationLoaded ? state.unreadByType : const <NotificationType, int>{};
        final hasUnread = unreadCount > 0;
        final filteredItems = _filtered(items);

        return Scaffold(
          backgroundColor: const Color(0xFFFDFBF7),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              l10n.notificationsTitle,
              style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50)),
              onPressed: () => getx.Get.back(),
            ),
            actions: [
              TextButton(
                onPressed: hasUnread ? () => getIt<NotificationCubit>().markAllAsRead() : null,
                child: Text(
                  l10n.notificationsMarkAllRead,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: hasUnread ? const Color(0xFFE67E22) : const Color(0xFFBDC3C7),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.notificationsDeleteAllTooltip,
                icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFF7F8C8D)),
                onPressed: items.isEmpty ? null : () => _confirmDeleteAll(context, l10n),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _FilterChip(
                      icon: Icons.notifications_rounded,
                      label: l10n.notificationsFilterAll,
                      selected: _filter == null,
                      count: unreadCount,
                      onTap: () => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      icon: Icons.receipt_long_rounded,
                      label: l10n.notificationsFilterOrder,
                      selected: _filter == NotificationType.order,
                      count: unreadByType[NotificationType.order] ?? 0,
                      onTap: () => setState(() => _filter = NotificationType.order),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      icon: Icons.local_offer_rounded,
                      label: l10n.notificationsFilterPromotion,
                      selected: _filter == NotificationType.voucher,
                      count: unreadByType[NotificationType.voucher] ?? 0,
                      onTap: () => setState(() => _filter = NotificationType.voucher),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      icon: Icons.campaign_rounded,
                      label: l10n.notificationsFilterSystem,
                      selected: _filter == NotificationType.system,
                      count: unreadByType[NotificationType.system] ?? 0,
                      onTap: () => setState(() => _filter = NotificationType.system),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state is NotificationLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFE67E22)),
                      )
                    : RefreshIndicator(
                        onRefresh: () => getIt<NotificationCubit>().loadNotifications(),
                        color: const Color(0xFFE67E22),
                        child: filteredItems.isEmpty
                            ? LayoutBuilder(
                                builder: (context, constraints) => SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(
                                    height: constraints.maxHeight,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.notifications_off_outlined, size: 64, color: Color(0xFFBDC3C7)),
                                            const SizedBox(height: 16),
                                            Text(
                                              l10n.notificationsEmptyTitle,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2C3E50),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              l10n.notificationsEmptySubtitle,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 13, color: Color(0xFF7F8C8D)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: filteredItems.length,
                                separatorBuilder: (c, i) => const SizedBox(height: 10),
                                itemBuilder: (context, idx) {
                                  final item = filteredItems[idx];
                                  final style = _styleFor(item.type);

                                  return Dismissible(
                                    key: ValueKey(item.id),
                                    direction: DismissDirection.endToStart,
                                    confirmDismiss: (_) => _confirmDeleteOne(context, l10n),
                                    onDismissed: (_) => getIt<NotificationCubit>().deleteNotification(item.id),
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE74C3C),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                                    ),
                                    child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => getIt<NotificationCubit>().markAsRead(item.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: item.isRead ? Colors.white : const Color(0xFFFDF6EE),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: item.isRead ? const Color(0xFFF1EAE1) : const Color(0xFFF5D5B0),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: style.color.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(style.icon, color: style.color, size: 22),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        item.title,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                                          color: const Color(0xFF2C3E50),
                                                        ),
                                                      ),
                                                    ),
                                                    if (!item.isRead)
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        margin: const EdgeInsets.only(left: 6, top: 4),
                                                        decoration: const BoxDecoration(
                                                          color: Color(0xFFE74C3C),
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.body,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D), height: 1.4),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _formatTime(l10n, item.time),
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFFBDC3C7)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE67E22) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? const Color(0xFFE67E22) : const Color(0xFFF1EAE1)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: selected ? Colors.white : const Color(0xFF7F8C8D)),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : const Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
              if (count > 0)
                Positioned(
                  top: -6,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
