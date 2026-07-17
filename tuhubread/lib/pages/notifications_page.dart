import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../data/mock_notifications.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotificationType? _filter;

  List<NotificationItem> get _filteredItems {
    final items = List<NotificationItem>.from(MockNotifications.items)
      ..sort((a, b) => b.time.compareTo(a.time));
    if (_filter == null) return items;
    return items.where((e) => e.type == _filter).toList();
  }

  void _markAllRead() {
    setState(() => MockNotifications.markAllAsRead());
  }

  void _markRead(NotificationItem item) {
    setState(() => item.isRead = true);
  }

  String _formatTime(AppLocalizations l10n, DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return l10n.notificationsJustNow;
    if (diff.inMinutes < 60) return l10n.notificationsMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.notificationsHoursAgo(diff.inHours);
    return l10n.notificationsDaysAgo(diff.inDays);
  }

  ({IconData icon, Color color}) _styleFor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return (icon: Icons.receipt_long_rounded, color: const Color(0xFFE67E22));
      case NotificationType.promotion:
        return (icon: Icons.local_offer_rounded, color: const Color(0xFFE74C3C));
      case NotificationType.system:
        return (icon: Icons.campaign_rounded, color: const Color(0xFF2980B9));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasUnread = MockNotifications.unreadCount > 0;

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
            onPressed: hasUnread ? _markAllRead : null,
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
                  selected: _filter == NotificationType.order,
                  onTap: () => setState(() => _filter = NotificationType.order),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  icon: Icons.local_offer_rounded,
                  label: l10n.notificationsFilterPromotion,
                  selected: _filter == NotificationType.promotion,
                  onTap: () => setState(() => _filter = NotificationType.promotion),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  icon: Icons.campaign_rounded,
                  label: l10n.notificationsFilterSystem,
                  selected: _filter == NotificationType.system,
                  onTap: () => setState(() => _filter = NotificationType.system),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
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
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _filteredItems.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final item = _filteredItems[idx];
                      final style = _styleFor(item.type);

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _markRead(item),
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
                                      _formatTime(l10n, item.time),
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
        ],
      ),
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
