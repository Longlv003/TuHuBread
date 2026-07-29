import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuhubread/blocs/notification/notification_cubit.dart';
import 'package:tuhubread/blocs/notification/notification_state.dart';
import 'package:tuhubread/models/notification.model.dart';
import 'package:tuhubread/routes/routes.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String? _filter; // 'order', 'promotion', 'system'

  @override
  void initState() {
    super.initState();
    // Load notifications when entering page
    context.read<NotificationCubit>().loadNotifications();
  }

  String _mapTypeToFilter(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('payment') || lower.contains('order')) {
      return 'order';
    }
    if (lower.contains('voucher') || lower.contains('promotion') || lower.contains('discount')) {
      return 'promotion';
    }
    return 'system';
  }

  String _formatTime(AppLocalizations l10n, DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return l10n.notificationsJustNow;
    if (diff.inMinutes < 60) return l10n.notificationsMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.notificationsHoursAgo(diff.inHours);
    return l10n.notificationsDaysAgo(diff.inDays);
  }

  ({IconData icon, Color color}) _styleFor(String category) {
    switch (category) {
      case 'order':
        return (icon: Icons.receipt_long_rounded, color: const Color(0xFFE67E22));
      case 'promotion':
        return (icon: Icons.local_offer_rounded, color: const Color(0xFFE74C3C));
      default:
        return (icon: Icons.campaign_rounded, color: const Color(0xFF2980B9));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final List<NotificationModel> allNotifications = state is NotificationLoaded
            ? state.notifications
            : [];
        final hasUnread = state is NotificationLoaded && state.unreadCount > 0;
        final isLoading = state is NotificationLoading;

        // Apply UI filter and sort by sent time
        final filteredItems = allNotifications.where((item) {
          if (_filter == null) return true;
          return _mapTypeToFilter(item.type) == _filter;
        }).toList()
          ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

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
                onPressed: hasUnread
                    ? () => context.read<NotificationCubit>().markAllAsRead()
                    : null,
                child: Text(
                  l10n.notificationsMarkAllRead,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: hasUnread ? const Color(0xFFE67E22) : const Color(0xFFBDC3C7),
                  ),
                ),
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
                      onTap: () => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      icon: Icons.receipt_long_rounded,
                      label: l10n.notificationsFilterOrder,
                      selected: _filter == 'order',
                      onTap: () => setState(() => _filter = 'order'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      icon: Icons.local_offer_rounded,
                      label: l10n.notificationsFilterPromotion,
                      selected: _filter == 'promotion',
                      onTap: () => setState(() => _filter = 'promotion'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      icon: Icons.campaign_rounded,
                      label: l10n.notificationsFilterSystem,
                      selected: _filter == 'system',
                      onTap: () => setState(() => _filter = 'system'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFE67E22)),
                      )
                    : filteredItems.isEmpty
                        ? Center(
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
                          )
                        : RefreshIndicator(
                            color: const Color(0xFFE67E22),
                            onRefresh: () => context.read<NotificationCubit>().loadNotifications(),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: filteredItems.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final item = filteredItems[idx];
                                final category = _mapTypeToFilter(item.type);
                                final style = _styleFor(category);

                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    if (!item.isRead) {
                                      context.read<NotificationCubit>().markAsRead(item.id);
                                    }
                                    // Navigate to order detail if it's order-related and has orderId
                                    if (category == 'order' && item.orderId != null && item.orderId!.isNotEmpty) {
                                      getx.Get.toNamed(Routes.trackOrderPage, arguments: item.orderId);
                                    }
                                  },
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
                                                item.message,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D), height: 1.4),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _formatTime(l10n, item.sentAt),
                                                style: const TextStyle(fontSize: 11, color: Color(0xFFBDC3C7)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
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
          child: Column(
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
        ),
      ),
    );
  }
}
