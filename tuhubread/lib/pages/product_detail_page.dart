import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../blocs/product_detail/product_detail_cubit.dart';
import '../blocs/product_detail/product_detail_state.dart';
import '../di.dart';
import '../models/product_option.model.dart';
import '../models/product_variant.model.dart';
import '../models/product_review.model.dart';
import '../models/product_detail.model.dart';
import '../utils/currency_formatter.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Nhận productId truyền qua arguments từ Getx
    final String productId = getx.Get.arguments as String;

    return BlocProvider<ProductDetailCubit>(
      create: (_) => getIt<ProductDetailCubit>()..loadProductDetail(productId),
      child: const _ProductDetailContent(),
    );
  }
}

class _ProductDetailContent extends StatelessWidget {
  const _ProductDetailContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      builder: (context, state) {
        if (state is ProductDetailLoading || state is ProductDetailInitial) {
          return const Scaffold(
            backgroundColor: Color(0xFFFDFBF7),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE67E22),
              ),
            ),
          );
        }

        if (state is ProductDetailFailure) {
          return Scaffold(
            backgroundColor: const Color(0xFFFDFBF7),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50)),
                onPressed: () => getx.Get.back(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 54, color: Color(0xFFE74C3C)),
                    const SizedBox(height: 16),
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        final String productId = getx.Get.arguments as String;
                        context.read<ProductDetailCubit>().loadProductDetail(productId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE67E22),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.retryButton),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is ProductDetailLoaded) {
          final detail = state.productDetail;
          final hasSale = detail.activeSale != null && detail.activeSale!.isActiveNow;

          return Scaffold(
            backgroundColor: const Color(0xFFFDFBF7),
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Sliver Image Header
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  stretch: true,
                  backgroundColor: const Color(0xFFE67E22),
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.4),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                        onPressed: () => getx.Get.back(),
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.blurBackground,
                    ],
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          detail.image,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: const Color(0xFFF1EAE1),
                            child: const Icon(
                              Icons.bakery_dining_rounded,
                              color: Color(0xFFE67E22),
                              size: 64,
                            ),
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black26, Colors.transparent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Body Details
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tên sản phẩm & rating
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  detail.productName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (detail.rating > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDF0E5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Color(0xFFF1C40F), size: 16),
                                      const SizedBox(width: 3),
                                      Text(
                                        "${detail.rating}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE67E22),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    l10n.detailNoRatingYet,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF95A5A6),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Giá tạm tính (Hiển thị đỏ to dưới tên sản phẩm)
                          Text(
                            CurrencyFormatter.formatVND(state.totalPrice),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE74C3C),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Thời gian chuẩn bị & Prep Time tag
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF7F8C8D)),
                              const SizedBox(width: 4),
                              Text(
                                l10n.detailPrepTime(detail.preparationTimeMinutes.toString()),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.shopping_bag_outlined, size: 14, color: Color(0xFF7F8C8D)),
                              const SizedBox(width: 4),
                              Text(
                                "Đã bán ${detail.salesCount}",
                                style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                              ),
                            ],
                          ),
                          const Divider(height: 32, color: Color(0xFFF1EAE1)),

                          // ─────────── 3. THÔNG TIN CỬA HÀNG (SHOP) ───────────
                          if (detail.shop != null) ...[
                            _buildShopSection(context, detail.shop!, l10n),
                            const Divider(height: 32, color: Color(0xFFF1EAE1)),
                          ],

                          // ─────────── 3b. CÁC CHI NHÁNH KHÁC CÙNG BÁN MÓN NÀY ───────────
                          if (detail.otherShops.isNotEmpty) ...[
                            _buildOtherShopsSection(context, detail.otherShops, l10n),
                            const Divider(height: 32, color: Color(0xFFF1EAE1)),
                          ],

                          // 4. Phần mô tả chi tiết sản phẩm
                          Text(
                            l10n.detailDescription,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            detail.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7F8C8D),
                              height: 1.5,
                            ),
                          ),
                          const Divider(height: 32, color: Color(0xFFF1EAE1)),

                          // 5. Chọn kích cỡ (Variants)
                          _buildVariantsSection(context, detail.variants, state.selectedVariant, hasSale, l10n),
                          const Divider(height: 32, color: Color(0xFFF1EAE1)),

                          // 6. Chọn số lượng mua (Quantity)
                          _buildQuantitySection(context, state.quantity, l10n),
                          const Divider(height: 32, color: Color(0xFFF1EAE1)),

                          // 7. Tùy chọn thêm (Options)
                          if (detail.options.isNotEmpty) ...[
                            _buildOptionsSection(context, detail.options, state.selectedOptionIds, l10n),
                            const Divider(height: 32, color: Color(0xFFF1EAE1)),
                          ],

                          // ─────────── 8. ĐÁNH GIÁ & BÌNH LUẬN (REVIEWS) ───────────
                          _buildReviewsSection(context, detail.reviews ?? [], detail.totalReviews ?? 0, l10n),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
            ),

            // 9. Bottom Bar (Thêm vào giỏ hàng + Mua ngay)
            bottomNavigationBar: _buildBottomActionBar(context, l10n),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ─────────── HIỂN THỊ THÔNG TIN CỬA HÀNG ───────────

  Widget _buildShopSection(BuildContext context, dynamic shop, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.detailShopSection,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1EAE1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: shop.logo != null
                    ? Image.network(
                        shop.logo!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 44,
                          height: 44,
                          color: const Color(0xFFFDF0E5),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFFE67E22),
                            size: 24,
                          ),
                        ),
                      )
                    : Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFFFDF0E5),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFFE67E22),
                          size: 24,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.shopName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF7F8C8D)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shop.address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF7F8C8D)),
                        const SizedBox(width: 4),
                        Text(
                          l10n.detailShopPhone(shop.phoneNumber),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────── CÁC CHI NHÁNH KHÁC CÙNG BÁN MÓN NÀY ───────────

  Widget _buildOtherShopsSection(
    BuildContext context,
    List<ProductDetailOtherShopModel> otherShops,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.detailOtherShopsSection,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: otherShops.length,
          separatorBuilder: (c, i) => const SizedBox(height: 8),
          itemBuilder: (c, idx) {
            final other = otherShops[idx];
            final displayPrice = other.salePrice ?? other.price;

            return InkWell(
              onTap: () {
                // Tải lại chi tiết sản phẩm của cửa hàng khác
                context.read<ProductDetailCubit>().loadProductDetail(other.productId);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1EAE1)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFF7F8C8D),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            other.shopName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (other.salePrice != null) ...[
                                Text(
                                  CurrencyFormatter.formatVND(other.price),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFBDC3C7),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                CurrencyFormatter.formatVND(displayPrice),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE74C3C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE67E22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Xem giá",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─────────── BỘ TĂNG GIẢM SỐ LƯỢNG ───────────

  Widget _buildQuantitySection(BuildContext context, int quantity, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.detailQuantity,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1EAE1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, color: Color(0xFFE67E22), size: 18),
                onPressed: () => context.read<ProductDetailCubit>().decrementQuantity(),
              ),
              Text(
                "$quantity",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: Color(0xFFE67E22), size: 18),
                onPressed: () => context.read<ProductDetailCubit>().incrementQuantity(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────── CHỌN KÍCH CỠ (VARIANTS) ───────────

  Widget _buildVariantsSection(
    BuildContext context,
    List<ProductVariantModel> variants,
    ProductVariantModel selected,
    bool hasSaleProduct,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.detailSelectSize,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: variants.map((variant) {
            final isSelected = variant.id == selected.id;
            final hasSale = variant.salePrice != null || hasSaleProduct;
            
            double originalPrice = variant.price;
            double displayPrice = originalPrice;
            if (variant.salePrice != null) {
              displayPrice = variant.salePrice!;
            } else if (hasSaleProduct) {
              final loadedState = context.read<ProductDetailCubit>().state as ProductDetailLoaded;
              final activeSale = loadedState.productDetail.activeSale;
              if (activeSale != null && (activeSale.variantId == null || activeSale.variantId == variant.id)) {
                displayPrice = activeSale.salePrice;
              }
            }

            return GestureDetector(
              onTap: () => context.read<ProductDetailCubit>().selectVariant(variant),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFDF0E5) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE67E22) : const Color(0xFFF1EAE1),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      variant.variantName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFFD35400) : const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasSale && originalPrice != displayPrice) ...[
                          Text(
                            CurrencyFormatter.formatVND(originalPrice),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFFBDC3C7),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          CurrencyFormatter.formatVND(displayPrice),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFFD35400) : const Color(0xFFE67E22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─────────── TÙY CHỌN THÊM (OPTIONS) ───────────

  Widget _buildOptionsSection(
    BuildContext context,
    List<ProductOptionModel> options,
    Set<String> selectedIds,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.detailExtraOptions,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          separatorBuilder: (c, i) => const Divider(height: 1, color: Color(0xFFFDF9F3)),
          itemBuilder: (context, idx) {
            final option = options[idx];
            final isChecked = selectedIds.contains(option.id);

            return InkWell(
              onTap: () => context.read<ProductDetailCubit>().toggleOption(option.id),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isChecked ? const Color(0xFFE67E22) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isChecked ? const Color(0xFFE67E22) : const Color(0xFFBDC3C7),
                          width: 1.5,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                          : const SizedBox(width: 14, height: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.optionName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    Text(
                      "+${CurrencyFormatter.formatVND(option.extraPrice)}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─────────── HIỂN THỊ ĐÁNH GIÁ (REVIEWS) ───────────

  Widget _buildReviewsSection(
    BuildContext context,
    List<ProductReviewModel> reviews,
    int totalCount,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.detailReviewsSection(totalCount.toString()),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                l10n.detailNoReviews,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7F8C8D),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (c, i) => const Divider(height: 24, color: Color(0xFFF1EAE1)),
            itemBuilder: (context, idx) {
              final review = reviews[idx];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar nguoi dung
                      ClipOval(
                        child: review.user.avatar != null
                            ? Image.network(
                                review.user.avatar!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 36,
                                  height: 36,
                                  color: const Color(0xFFF1EAE1),
                                  child: const Icon(Icons.person, color: Color(0xFF7F8C8D), size: 18),
                                ),
                              )
                            : Container(
                                width: 36,
                                height: 36,
                                color: const Color(0xFFF1EAE1),
                                child: const Icon(Icons.person, color: Color(0xFF7F8C8D), size: 18),
                              ),
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
                            // Render ngoi sao vang dua vao rating
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  Icons.star_rounded,
                                  color: index < review.rating
                                      ? const Color(0xFFF1C40F)
                                      : const Color(0xFFBDC3C7),
                                  size: 14,
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (review.comment != null && review.comment!.isNotEmpty)
                    Text(
                      review.comment!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF34495E),
                        height: 1.4,
                      ),
                    ),
                  if (review.images.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: review.images.length,
                        separatorBuilder: (c, i) => const SizedBox(width: 8),
                        itemBuilder: (c, imgIdx) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            review.images[imgIdx],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }

  // ─────────── BOTTOM BAR MUA HÀNG ───────────

  Widget _buildBottomActionBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.detailAddedToCart),
                      backgroundColor: const Color(0xFF27AE60),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  getx.Get.back();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE67E22), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.detailAddToCart,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE67E22),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.detailBuyNowSuccess),
                      backgroundColor: const Color(0xFFE67E22),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  getx.Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  l10n.detailBuyNow,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
