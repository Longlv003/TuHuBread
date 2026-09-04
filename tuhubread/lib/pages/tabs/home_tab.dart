import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../../blocs/home/home_cubit.dart';
import '../../blocs/home/home_state.dart';
import '../../di.dart';
import '../../helpers/cart_action_helper.dart';
import '../../services/location_service.dart';
import '../../models/category.model.dart';
import '../../models/product.model.dart';
import '../../models/shop.model.dart';
import '../../models/user.model.dart';
import '../../models/voucher.model.dart';
import '../../routes/routes.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/horizontal_product_card.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/tap_scale.dart';
import '../category_products_page.dart';

/// Cách sắp xếp danh sách cửa hàng ở màn hình chủ (giống ShopeeFood).
enum _ShopSort { nearby, bestSelling, rating }

class HomeTab extends StatelessWidget {
  final UserModel user;

  /// Gọi mỗi khi hướng cuộn thay đổi — true = đang cuộn xuống (nên ẩn tab
  /// bar để nhường diện tích), false = đang cuộn lên/về đầu trang (nên hiện
  /// lại). Dùng để làm hiệu ứng tab bar tự ẩn/hiện kiểu Grab.
  final ValueChanged<bool>? onScrollHide;

  const HomeTab({super.key, required this.user, this.onScrollHide});

  @override
  Widget build(BuildContext context) {
    return _HomeTabContent(user: user, onScrollHide: onScrollHide);
  }
}

class _HomeTabContent extends StatefulWidget {
  final UserModel user;
  final ValueChanged<bool>? onScrollHide;

  const _HomeTabContent({required this.user, this.onScrollHide});

  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
  // Countdown timer — tick mỗi giây để cập nhật UI
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  // PageController cho Voucher Slider và Timer tự động chạy
  final PageController _voucherPageController = PageController();
  Timer? _voucherSliderTimer;

  // Set tracking voucher IDs user đã save (mock local state)
  final Set<String> _savedVoucherIds = {};

  // Theo dõi hướng cuộn để tự ẩn/hiện tab bar (kiểu Grab)
  final ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0;
  bool _navHidden = false;

  // Cách sắp xếp danh sách cửa hàng (Gần tôi / Bán chạy / Đánh giá)
  _ShopSort _shopSort = _ShopSort.nearby;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });

    // Auto-scroll Voucher Slide mỗi 3 giây
    _voucherSliderTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final homeState = context.read<HomeCubit>().state;
      if (homeState is! HomeLoaded) return;
      final visibleVouchers = _getVisibleVouchers(homeState);
      if (visibleVouchers.isEmpty) return;
      if (_voucherPageController.hasClients) {
        int nextPage = _voucherPageController.page!.toInt() + 1;
        if (nextPage >= visibleVouchers.length) {
          nextPage = 0;
        }
        _voucherPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    // Bỏ qua rung lắc nhỏ (đầu ngón tay run, hiệu ứng bounce...) — chỉ phản
    // ứng khi kéo đủ xa để chắc chắn là người dùng thật sự đang cuộn.
    if (delta.abs() < 6) return;

    final shouldHide = delta > 0 && offset > 40;
    if (shouldHide != _navHidden) {
      _navHidden = shouldHide;
      widget.onScrollHide?.call(shouldHide);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _voucherSliderTimer?.cancel();
    _voucherPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────── COMPUTED PROPERTIES / HELPERS ───────────

  /// Vouchers hiển thị trên UI — trả về rỗng khi:
  /// 1. API lỗi hoặc chưa có dữ liệu (vouchers empty)
  /// 2. User đã save tất cả voucher còn lại
  /// 3. Tất cả voucher đã hết mã (claimedCount >= claimLimit)
  /// → build() dùng .isNotEmpty để ẩn/hiện toàn bộ section Voucher
  List<VoucherModel> _getVisibleVouchers(HomeLoaded state) {
    return state.vouchers.where((v) {
      final isSaved = _savedVoucherIds.contains(v.id);
      final isFull = v.claimLimit != null && v.claimedCount >= v.claimLimit!;
      return !isSaved && !isFull;
    }).toList();
  }

  /// Sản phẩm của các cửa hàng trong danh sách hiện tại (backend đã lọc theo
  /// bán kính) — dùng cho các mục "Món đang giảm giá"/"Món nổi bật" để chúng
  /// luôn thuộc cửa hàng gần khách, đúng yêu cầu nghiệp vụ.
  List<ProductModel> _productsOfNearbyShops(HomeLoaded state) {
    final nearbyShopIds = state.shops.map((s) => s.id).toSet();
    return state.products
        .where((p) => nearbyShopIds.contains(p.shopId))
        .toList();
  }

  List<ProductModel> _getDiscountedProducts(HomeLoaded state) {
    final list = _productsOfNearbyShops(state).where((p) => p.hasDiscount).toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    return list.take(10).toList();
  }

  List<ProductModel> _getFeaturedProducts(HomeLoaded state) {
    return _productsOfNearbyShops(state)
        .where((p) => p.isFeatured && !p.hasDiscount)
        .take(10)
        .toList();
  }

  /// Danh mục có thật trong các cửa hàng gần khách — không hiện danh mục rỗng.
  List<CategoryModel> _getAvailableCategories(HomeLoaded state) {
    final categoryIds =
        _productsOfNearbyShops(state).map((p) => p.categoryId).toSet();
    return state.categories.where((c) => categoryIds.contains(c.id)).toList();
  }

  /// Danh sách cửa hàng đã sắp xếp theo tab đang chọn. `state.shops` đã được
  /// backend lọc sẵn theo bán kính 10km nên cả 3 tab đều chỉ hiện cửa hàng
  /// trong phạm vi đó.
  List<ShopModel> _getVisibleShops(HomeLoaded state) {
    final nearbyProducts = _productsOfNearbyShops(state);
    final result = state.shops.toList();

    switch (_shopSort) {
      case _ShopSort.nearby:
        // Backend đã trả về theo thứ tự gần nhất; shop thiếu toạ độ xếp cuối.
        result.sort(
          (a, b) => (a.distanceKm ?? double.infinity)
              .compareTo(b.distanceKm ?? double.infinity),
        );
      case _ShopSort.bestSelling:
        final soldByShop = <String, int>{};
        for (final p in nearbyProducts) {
          soldByShop[p.shopId] = (soldByShop[p.shopId] ?? 0) + p.salesCount;
        }
        result.sort(
          (a, b) => (soldByShop[b.id] ?? 0).compareTo(soldByShop[a.id] ?? 0),
        );
      case _ShopSort.rating:
        result.sort(
          (a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0),
        );
    }
    return result;
  }

  // ─────────── BUILD ───────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        // Khung chờ mô phỏng bố cục thật thay vì vòng xoay giữa màn hình —
        // người dùng thấy ngay trang sắp có gì và không bị "nhảy" bố cục khi
        // dữ liệu về.
        if (state is HomeLoading) return const HomeSkeleton();

        if (state is HomeFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Color(0xFFE74C3C),
                ),
                const SizedBox(height: 12),
                Text(
                  state.error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7F8C8D),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<HomeCubit>().refresh(),
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
          );
        }

        if (state is HomeLoaded) {
          final visibleVouchers = _getVisibleVouchers(state);
          final discounted = _getDiscountedProducts(state);
          final featured = _getFeaturedProducts(state);
          final categories = _getAvailableCategories(state);

          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().refresh(),
            color: const Color(0xFFE67E22),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Voucher Slider
                  if (visibleVouchers.isNotEmpty) ...[
                    _buildVoucherSlider(l10n, visibleVouchers),
                    const SizedBox(height: 24),
                  ],

                  // 2. Món đang giảm giá (chỉ từ cửa hàng gần khách)
                  if (discounted.isNotEmpty) ...[
                    _buildProductsSection(
                      title: l10n.homeDiscountedSection,
                      icon: Icons.local_fire_department_rounded,
                      accent: const Color(0xFFE74C3C),
                      products: discounted,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 3. Món nổi bật
                  if (featured.isNotEmpty) ...[
                    _buildProductsSection(
                      title: l10n.homeFeaturedSection,
                      icon: Icons.star_rounded,
                      accent: const Color(0xFFE67E22),
                      products: featured,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 4. Danh mục dạng icon — bấm vào mở trang riêng liệt kê
                  // sản phẩm thuộc danh mục đó (trong bán kính giao hàng).
                  if (categories.isNotEmpty) ...[
                    _buildCategoryGrid(categories, state, l10n),
                    const SizedBox(height: 20),
                  ],

                  // 5. Tab sắp xếp + danh sách Shop
                  _buildSortTabs(l10n),
                  const SizedBox(height: 14),
                  // Backend chỉ trả distance_km khi biết vị trí khách — dùng
                  // chính nó làm dấu hiệu danh sách có thực sự được lọc theo
                  // bán kính hay không.
                  _buildShopsSection(
                    _getVisibleShops(state),
                    l10n,
                    hasLocation: state.shops.any((s) => s.distanceKm != null),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ─────────── MỤC SẢN PHẨM (GIẢM GIÁ / NỔI BẬT) ───────────

  Widget _buildProductsSection({
    required String title,
    required IconData icon,
    required Color accent,
    required List<ProductModel> products,
    required AppLocalizations l10n,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accent, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: HorizontalProductCard.height,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: products.length,
            itemBuilder: (context, idx) {
              final product = products[idx];
              return HorizontalProductCard(
                product: product,
                onTap: () => getx.Get.toNamed(
                  Routes.productDetailPage,
                  arguments: product.id,
                ),
                onAddToCart: () => CartActionHelper.quickAddProductWithFeedback(
                  context,
                  product.id,
                  successMessage: l10n.detailAddedToCart,
                  failureFallback: l10n.cartAddFailed,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────── DANH MỤC DẠNG ICON ───────────

  Widget _buildCategoryGrid(
    List<CategoryModel> categories,
    HomeLoaded state,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            l10n.homeCategoriesSection,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: categories.length,
            itemBuilder: (context, idx) =>
                _buildCategoryIcon(categories[idx], state),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryIcon(CategoryModel category, HomeLoaded state) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: TapScale(
        pressedScale: 0.92,
        onTap: () => getx.Get.to(
          () => CategoryProductsPage(
            category: category,
            products: _productsOfNearbyShops(state),
            nearbyShops: state.shops,
          ),
        ),
        child: SizedBox(
          width: 66,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF1EAE1)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: AppNetworkImage(
                  url: category.categoryIcon,
                  fallbackIconSize: 26,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category.categoryName,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────── TAB SẮP XẾP ───────────

  Widget _buildSortTabs(AppLocalizations l10n) {
    final labels = {
      _ShopSort.nearby: l10n.filterNearMe,
      _ShopSort.bestSelling: l10n.filterBestSelling,
      _ShopSort.rating: l10n.filterRating,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1EAE1)),
      ),
      child: Row(
        children: _ShopSort.values.map((sort) {
          final isSelected = _shopSort == sort;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _shopSort = sort),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? const Color(0xFFE67E22)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  labels[sort]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFFE67E22)
                        : const Color(0xFF7F8C8D),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────── SHOP SELECTOR ───────────

  /// Chủ động xin quyền + lấy GPS rồi tải lại trang chủ.
  ///
  /// Dùng [LocationService.requestCurrentLocation] (bản ném lỗi cụ thể) thay
  /// vì bản chạy ngầm im lặng — người dùng đã bấm nút nên cần biết rõ vì sao
  /// không lấy được và phải làm gì tiếp.
  Future<void> _requestLocationAndReload() async {
    final locationService = getIt<LocationService>();
    final messenger = ScaffoldMessenger.of(context);
    final homeCubit = context.read<HomeCubit>();
    final l10n = AppLocalizations.of(context)!;

    try {
      final coords = await locationService.requestCurrentLocation();
      await homeCubit.updateDeliveryLocation(
        coords.latitude,
        coords.longitude,
      );
    } on LocationException catch (e) {
      if (!mounted) return;
      final (message, actionLabel, action) = switch (e.reason) {
        LocationFailureReason.serviceDisabled => (
            l10n.homeLocationOffHint,
            l10n.homeOpenSettings,
            Geolocator.openLocationSettings,
          ),
        LocationFailureReason.permissionDeniedForever => (
            l10n.homeLocationDeniedHint,
            l10n.homeOpenSettings,
            Geolocator.openAppSettings,
          ),
        LocationFailureReason.permissionDenied => (
            l10n.homeLocationRequiredHint,
            null,
            null,
          ),
        LocationFailureReason.timeout => (
            l10n.homeLocationFailedHint,
            null,
            null,
          ),
      };

      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFE74C3C),
          action: (actionLabel != null && action != null)
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: () => action(),
                )
              : null,
        ),
      );
    }
  }

  /// Khối nhắc bật/ghim vị trí khi chưa xác định được khách ở đâu.
  Widget _buildNoLocationNotice(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5E6B8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_off_rounded,
            size: 18,
            color: Color(0xFF9C7A0A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeLocationUnknown,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9C7A0A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.homeLocationFallbackHint,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF9C7A0A),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _requestLocationAndReload,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE67E22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.homeUseCurrentLocation,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildShopsSection(
    List<ShopModel> shops,
    AppLocalizations l10n, {
    required bool hasLocation,
  }) {
    // [hasLocation] được suy ra từ việc có shop nào kèm khoảng cách hay không,
    // nên khi danh sách RỖNG nó luôn bằng false — không có nghĩa là mất vị trí,
    // mà chỉ là quanh đây không có cửa hàng nào. Lúc đó chỉ hiện đúng một
    // thông báo "chưa có cửa hàng", không kèm cảnh báo vị trí gây hiểu nhầm.
    final showAllShopsFallback = !hasLocation && shops.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFFE67E22),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                showAllShopsFallback ? l10n.homeAllShops : l10n.homeShopsNearYou,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "(${shops.length})",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFBDC3C7),
                ),
              ),
            ],
          ),
        ),
        // Chưa xác định được vị trí thì danh sách này KHÔNG phải "gần bạn" —
        // nói thẳng và chỉ cách khắc phục, thay vì lặng lẽ hiện toàn bộ cửa
        // hàng như thể chúng đều ở gần.
        if (showAllShopsFallback) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildNoLocationNotice(l10n),
          ),
        ],
        const SizedBox(height: 14),
        if (shops.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1EAE1)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.store_mall_directory_outlined,
                    size: 40,
                    color: Color(0xFFBDC3C7),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.homeNoShopNearby,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: shops.length,
            itemBuilder: (context, idx) {
              final shop = shops[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFF1EAE1),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      getx.Get.toNamed(
                        Routes.shopHomePage,
                        arguments: {
                          'shop': shop,
                          'homeCubit': context.read<HomeCubit>(),
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Quán đang đóng thì làm mờ logo để nhìn lướt qua
                          // cũng phân biệt được ngay với quán đang mở.
                          Opacity(
                            opacity: shop.isOpen ? 1 : 0.45,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AppNetworkImage(
                                url: shop.logo,
                                width: 64,
                                height: 64,
                                fallbackIcon: Icons.store_rounded,
                                fallbackIconSize: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        shop.shopName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: shop.isOpen
                                              ? const Color(0xFF2C3E50)
                                              : const Color(0xFF95A5A6),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!shop.isOpen) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFDECEA),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          l10n.labelClosed,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFE74C3C),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF6E5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFF1C40F),
                                            size: 13,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            shop.rating == null
                                                ? l10n.labelNew
                                                : "${shop.rating}",
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF7F8C8D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (shop.distanceKm != null) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.near_me_rounded,
                                        color: Color(0xFF95A5A6),
                                        size: 12,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${shop.distanceKm} km',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7F8C8D),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.phone_in_talk_rounded,
                                      color: Color(0xFF95A5A6),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        shop.phone,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF7F8C8D),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.place_rounded,
                                      size: 13,
                                      color: Color(0xFFBDC3C7),
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        shop.address,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF95A5A6),
                                          height: 1.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFDF6EE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: Color(0xFFE67E22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ─────────── VOUCHER SLIDER ───────────

  Widget _buildVoucherSlider(
    AppLocalizations l10n,
    List<VoucherModel> visibleVouchers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: Color(0xFFE67E22),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.homePromoForYou,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${visibleVouchers.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 88,
          child: PageView.builder(
            controller: _voucherPageController,
            physics: const BouncingScrollPhysics(),
            itemCount: visibleVouchers.length,
            itemBuilder: (context, idx) =>
                _buildVoucherCard(visibleVouchers[idx], l10n),
          ),
        ),
      ],
    );
  }

  String _formatCountdown(Duration d, AppLocalizations l10n) {
    if (d.isNegative) return l10n.homeExpired;
    if (d.inDays >= 1) return '${d.inDays}n ${d.inHours % 24}g';
    if (d.inHours >= 1) {
      return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Widget _buildVoucherCard(VoucherModel voucher, AppLocalizations l10n) {
    final remaining = voucher.endDate.difference(_now);
    final isSaved = _savedVoucherIds.contains(voucher.id);
    final isFull =
        voucher.claimLimit != null &&
        voucher.claimedCount >= voucher.claimLimit!;
    final isPercent = voucher.discountType == 'percent';
    final isFlash = voucher.claimLimit != null;

    final gradientColors = isFlash
        ? [const Color(0xFFFFF0E0), const Color(0xFFFFD9B3)]
        : [const Color(0xFFE8F4FD), const Color(0xFFD0EAFA)];
    final accentColor = isFlash
        ? const Color(0xFFE67E22)
        : const Color(0xFF2980B9);
    final borderColor = isFlash
        ? const Color(0xFFFFB347)
        : const Color(0xFF87CEEB);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon tròn bên trái
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.confirmation_num_rounded,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),

          // Thông tin voucher ở giữa
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        voucher.voucherName,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFlash) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.homeFlash,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isPercent
                      ? l10n.homeDiscountPercentFormat(
                          voucher.discountValue.toInt().toString(),
                          CurrencyFormatter.formatVND(
                            voucher.maxDiscountAmount ?? 0,
                          ),
                        )
                      : l10n.homeDiscountFormat(
                          CurrencyFormatter.formatVND(voucher.discountValue),
                          CurrencyFormatter.formatVND(voucher.minOrderAmount),
                        ),
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 10,
                      color: remaining.inHours < 3
                          ? const Color(0xFFE74C3C)
                          : const Color(0xFF7F8C8D),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      remaining.isNegative
                          ? l10n.homeExpired
                          : _formatCountdown(remaining, l10n),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: remaining.inHours < 3
                            ? const Color(0xFFE74C3C)
                            : const Color(0xFF7F8C8D),
                      ),
                    ),
                    if (isFlash) ...[
                      const SizedBox(width: 8),
                      Text(
                        isFull
                            ? l10n.homeSoldOutVouchers
                            : l10n.homeRemainingVouchers(
                                (voucher.claimLimit! - voucher.claimedCount)
                                    .toString(),
                              ),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isFull
                              ? const Color(0xFFBDC3C7)
                              : const Color(0xFFE67E22),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Nút lưu bên phải
          GestureDetector(
            onTap: isFull || isSaved || remaining.isNegative
                ? null
                : () {
                    setState(() => _savedVoucherIds.add(voucher.id));
                    // Cập nhật optimistic count trong Cubit và lưu lên backend
                    context.read<HomeCubit>().saveVoucher(voucher.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.homeClaimedVoucherSnackbar(voucher.voucherCode),
                        ),
                        backgroundColor: const Color(0xFF27AE60),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isFull || remaining.isNegative
                    ? const Color(0xFFECF0F1)
                    : isSaved
                    ? const Color(0xFF27AE60)
                    : accentColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isFull || remaining.isNegative
                    ? l10n.homeSoldOutVouchers
                    : isSaved
                    ? l10n.homeClaimed
                    : l10n.homeClaimVoucher,
                style: TextStyle(
                  color: isFull || remaining.isNegative
                      ? const Color(0xFFBDC3C7)
                      : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
