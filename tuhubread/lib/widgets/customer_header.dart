import 'package:flutter/material.dart';
import '../models/user.model.dart';

class CustomerHeader extends StatelessWidget {
  final UserModel user;
  final Widget titleWidget;
  final int unreadNotifications;
  final VoidCallback onNotificationTap;

  /// Căn giữa tiêu đề (dùng cho các tab chỉ có tiêu đề chữ như Giỏ hàng).
  /// Khi bật, phía trái được chừa đúng bề rộng của nút chuông bên phải để
  /// tiêu đề nằm chính giữa màn hình thay vì bị lệch.
  final bool centerTitle;

  /// Nút phụ đặt bên trái tiêu đề (chỉ dùng khi [centerTitle] = true).
  final Widget? leading;

  const CustomerHeader({
    super.key,
    required this.user,
    required this.titleWidget,
    required this.unreadNotifications,
    required this.onNotificationTap,
    this.centerTitle = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (centerTitle)
            SizedBox(width: 40, child: leading),
          Expanded(
            child: centerTitle ? Center(child: titleWidget) : titleWidget,
          ),
          GestureDetector(
            onTap: onNotificationTap,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF0E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Color(0xFFD35400),
                    size: 24,
                  ),
                ),
                if (unreadNotifications > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE74C3C),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          '$unreadNotifications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
