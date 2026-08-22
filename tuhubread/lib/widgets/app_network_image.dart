import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/app_tokens.dart';

/// Ảnh tải từ mạng dùng chung cho toàn app.
///
/// Thay cho [Image.network] vốn KHÔNG lưu cache xuống đĩa: mỗi lần cuộn qua
/// lại hay mở lại màn hình là tải lại ảnh từ đầu, vừa tốn dữ liệu vừa làm ảnh
/// nháy trắng. [CachedNetworkImage] lưu lại nên lần sau hiện ra tức thì, kèm
/// khối chờ mờ dần thay vì khoảng trống rồi ảnh nhảy vào đột ngột.
class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Icon hiển thị khi ảnh lỗi/không có — mặc định là icon bánh mì cho hợp
  /// bối cảnh sản phẩm.
  final IconData fallbackIcon;
  final double fallbackIconSize;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.bakery_dining_rounded,
    this.fallbackIconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _buildFallback();

    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 220),
      placeholder: (context, _) => Container(
        width: width,
        height: height,
        color: AppColors.skeletonBase,
      ),
      errorWidget: (context, _, __) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.border,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: AppColors.primary,
        size: fallbackIconSize,
      ),
    );
  }
}
