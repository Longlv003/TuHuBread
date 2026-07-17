import 'package:flutter/material.dart';

/// Đường kẻ đứt nét dọc — dùng làm ranh giới giữa 2 nửa của thẻ voucher
/// kiểu "ticket" (giống Shopee).
///
/// Dùng CustomPaint thay vì LayoutBuilder vì widget này thường nằm trong
/// IntrinsicHeight (ví dụ Row của thẻ voucher) — LayoutBuilder không hỗ trợ
/// tính intrinsic dimensions và sẽ throw exception, khiến cả cây widget cha
/// render lỗi (danh sách hiển thị trống dù dữ liệu tải về đầy đủ).
class VerticalDashedDivider extends StatelessWidget {
  final Color color;
  final double dashHeight;
  final double dashGap;

  const VerticalDashedDivider({
    super.key,
    this.color = const Color(0xFFF1EAE1),
    this.dashHeight = 4,
    this.dashGap = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      child: CustomPaint(
        size: const Size(1, double.infinity),
        painter: _DashedLinePainter(color: color, dashHeight: dashHeight, dashGap: dashGap),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double dashGap;

  _DashedLinePainter({required this.color, required this.dashHeight, required this.dashGap});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    double y = 0;
    while (y < size.height) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, dashHeight), paint);
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashHeight != dashHeight || oldDelegate.dashGap != dashGap;
}
