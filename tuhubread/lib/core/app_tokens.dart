import 'package:flutter/material.dart';

/// Bộ giá trị thiết kế dùng chung (màu, bo góc, đổ bóng, khoảng cách).
///
/// Hiện tại phần lớn màn hình vẫn viết thẳng mã màu dạng `Color(0xFFE67E22)`.
/// File này KHÔNG nhằm thay thế toàn bộ ngay lập tức (sẽ phải sửa hàng trăm
/// chỗ, rủi ro cao) — mà để code mới và các phần chỉnh sửa dần dùng chung một
/// nguồn, tránh mỗi màn một sắc cam/xám hơi khác nhau.
class AppColors {
  const AppColors._();

  static const primary = Color(0xFFE67E22);
  static const primaryDark = Color(0xFFD35400);
  static const primaryTint = Color(0xFFFDF0E5);

  static const bg = Color(0xFFFDFBF7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFFAF6F0);
  static const border = Color(0xFFF1EAE1);

  static const text = Color(0xFF2C3E50);
  static const textMuted = Color(0xFF7F8C8D);
  static const textFaint = Color(0xFF95A5A6);
  static const textDisabled = Color(0xFFBDC3C7);

  static const success = Color(0xFF27AE60);
  static const warning = Color(0xFFF1C40F);
  static const danger = Color(0xFFE74C3C);

  /// Nền của khối skeleton khi đang tải dữ liệu.
  static const skeletonBase = Color(0xFFEDE7DF);
  static const skeletonHighlight = Color(0xFFF7F3EE);
}

class AppRadius {
  const AppRadius._();

  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const pill = 999.0;
}

class AppShadows {
  const AppShadows._();

  /// Bóng nhẹ cho thẻ trên nền sáng — mềm và khuếch tán, tránh viền cứng.
  static const card = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 4)),
  ];

  static const raised = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
}
