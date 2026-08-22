import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;

import '../models/product_review.model.dart';

/// Trang xem toàn bộ đánh giá của 1 sản phẩm. Tách riêng khỏi trang chi tiết
/// để trang chi tiết không bị kéo dài bởi danh sách bình luận — ở đó chỉ hiện
/// 1 dòng tóm tắt bấm được để mở trang này.
class ProductReviewsPage extends StatefulWidget {
  final String productName;
  final double rating;
  final int totalReviews;
  final List<ProductReviewModel> reviews;

  const ProductReviewsPage({
    super.key,
    required this.productName,
    required this.rating,
    required this.totalReviews,
    required this.reviews,
  });

  @override
  State<ProductReviewsPage> createState() => _ProductReviewsPageState();
}

class _ProductReviewsPageState extends State<ProductReviewsPage> {
  /// null = xem tất cả, ngược lại chỉ hiện đánh giá đúng số sao này.
  int? _starFilter;

  /// Số lượng đánh giá theo từng mức sao, dùng cho dãy nút lọc 5★..1★.
  Map<int, int> get _countByStar {
    final counts = <int, int>{for (var i = 1; i <= 5; i++) i: 0};
    for (final r in widget.reviews) {
      final star = r.rating.round().clamp(1, 5);
      counts[star] = (counts[star] ?? 0) + 1;
    }
    return counts;
  }

  List<ProductReviewModel> get _visibleReviews {
    if (_starFilter == null) return widget.reviews;
    return widget.reviews
        .where((r) => r.rating.round().clamp(1, 5) == _starFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final counts = _countByStar;
    final visible = _visibleReviews;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Đánh giá sản phẩm',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50)),
          onPressed: () => getx.Get.back(),
        ),
      ),
      body: Column(
        children: [
          _buildSummary(counts),
          const Divider(height: 1, color: Color(0xFFF1EAE1)),
          Expanded(
            child: visible.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Chưa có đánh giá nào ở mức này',
                        style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: visible.length,
                    separatorBuilder: (c, i) =>
                        const Divider(height: 28, color: Color(0xFFF1EAE1)),
                    itemBuilder: (context, idx) => _ReviewTile(review: visible[idx]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(Map<int, int> counts) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE67E22),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < widget.rating.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFF1C40F),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.totalReviews} đánh giá',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStarChip(label: 'Tất cả', value: null, count: widget.reviews.length),
                for (var star = 5; star >= 1; star--)
                  _buildStarChip(label: '$star★', value: star, count: counts[star] ?? 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarChip({
    required String label,
    required int? value,
    required int count,
  }) {
    final isSelected = _starFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _starFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFDF0E5) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFFE67E22) : const Color(0xFFF1EAE1),
            ),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFFE67E22) : const Color(0xFF7F8C8D),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ProductReviewModel review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipOval(
              child: review.user.avatar != null
                  ? Image.network(
                      review.user.avatar!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const _AvatarFallback(),
                    )
                  : const _AvatarFallback(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.user.fullName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        Icons.star_rounded,
                        color: index < review.rating
                            ? const Color(0xFFF1C40F)
                            : const Color(0xFFBDC3C7),
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (review.comment != null && review.comment!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            review.comment!,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF34495E),
              height: 1.4,
            ),
          ),
        ],
        if (review.images.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: review.images.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (c, imgIdx) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  review.images[imgIdx],
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      color: const Color(0xFFF1EAE1),
      child: const Icon(Icons.person, color: Color(0xFF7F8C8D), size: 18),
    );
  }
}
