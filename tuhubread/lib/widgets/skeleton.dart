import 'package:flutter/material.dart';

import '../core/app_tokens.dart';

/// Hiệu ứng "quét sáng" chạy ngang qua các khối skeleton bên trong.
///
/// Tự cài đặt bằng [AnimatedBuilder] + [LinearGradient] thay vì thêm gói
/// shimmer ngoài — chỉ vài chục dòng, tránh kéo thêm phụ thuộc vào dự án.
class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // Dịch dải sáng từ ngoài trái sang ngoài phải theo tiến trình.
            final dx = bounds.width * (_controller.value * 2 - 1);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.skeletonBase,
                AppColors.skeletonHighlight,
                AppColors.skeletonBase,
              ],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double dx;
  const _SlideGradient(this.dx);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// 1 khối xám bo góc — viên gạch dựng nên mọi bố cục skeleton.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Khung chờ của trang chủ — mô phỏng đúng bố cục thật (banner, hàng danh
/// mục, danh sách cửa hàng) để lúc dữ liệu về không bị "nhảy" bố cục.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner / voucher
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SkeletonBox(height: 120, radius: AppRadius.lg),
            ),
            const SizedBox(height: 24),

            // Hàng danh mục dạng icon tròn
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SkeletonBox(width: 100, height: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 92,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                itemBuilder: (context, _) => const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Column(
                    children: [
                      SkeletonBox(width: 56, height: 56, radius: 28),
                      SizedBox(height: 8),
                      SkeletonBox(width: 46, height: 10),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tab sắp xếp
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SkeletonBox(height: 38, radius: AppRadius.xl),
            ),
            const SizedBox(height: 16),

            // Danh sách cửa hàng
            for (int i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _ShopCardSkeleton(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShopCardSkeleton extends StatelessWidget {
  const _ShopCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(width: 86, height: 86, radius: AppRadius.md),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(height: 14),
              SizedBox(height: 8),
              SkeletonBox(width: 160, height: 11),
              SizedBox(height: 8),
              SkeletonBox(width: 110, height: 11),
              SizedBox(height: 12),
              SkeletonBox(width: 80, height: 11),
            ],
          ),
        ),
      ],
    );
  }
}

/// Khung chờ cho lưới sản phẩm 2 cột (trang danh mục, trang cửa hàng).
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.68,
        ),
        itemCount: itemCount,
        itemBuilder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(height: 110, radius: AppRadius.lg),
            SizedBox(height: 10),
            SkeletonBox(height: 13),
            SizedBox(height: 6),
            SkeletonBox(width: 90, height: 10),
            Spacer(),
            SkeletonBox(width: 70, height: 14),
          ],
        ),
      ),
    );
  }
}
