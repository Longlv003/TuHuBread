import 'package:flutter/material.dart';

/// Bọc quanh thẻ/nút để có phản hồi khi chạm: nhấn xuống thì thu nhỏ nhẹ, thả
/// ra thì bật lại.
///
/// Dùng thay cho hiệu ứng gợn sóng (InkWell) ở những thẻ có ảnh phủ kín và đổ
/// bóng — gợn sóng vẽ dưới nội dung nên bị ảnh che gần hết, còn thu nhỏ thì
/// luôn nhìn thấy rõ.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Tỉ lệ khi đang nhấn giữ. Càng nhỏ càng "lún" sâu.
  final double pressedScale;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // Không có onTap thì trả thẳng child — tránh chiếm sự kiện chạm của
    // widget bên trong một cách vô ích.
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
