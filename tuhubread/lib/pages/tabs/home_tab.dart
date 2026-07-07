import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../../blocs/home/home_cubit.dart';
import '../../blocs/home/home_state.dart';
import '../../gen/assets.gen.dart';
import '../../models/category.model.dart';
import '../../models/product.model.dart';
import '../../models/product_sale.model.dart';
import '../../models/shop.model.dart';
import '../../models/shop_category.model.dart';
import '../../models/user.model.dart';
import '../../models/voucher.model.dart';
import '../../routes/routes.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/horizontal_product_card.dart';
import '../../widgets/product_grid_card.dart';

class HomeTab extends StatelessWidget {
  final UserModel user;

  const HomeTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return _HomeTabContent(user: user);
  }
}

class _HomeTabContent extends StatefulWidget {
  final UserModel user;

  const _HomeTabContent({required this.user});

  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
  // '' = chưa chọn cửa hàng (xem global), khác '' = đã chọn shop cụ thể
  String _selectedShopId = '';
  String _selectedGlobalCategoryId = 'all';
  String _selectedShopCategoryId = 'all';
  String _searchQuery = '';

  // Countdown timer — tick mỗi giây để cập nhật UI
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  // PageController cho Voucher Slider và Timer tự động chạy
  final PageController _voucherPageController = PageController();
  Timer? _voucherSliderTimer;

  // Set tracking voucher IDs user đã save (mock local state)
  final Set<String> _savedVoucherIds = {};

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
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _voucherSliderTimer?.cancel();
    _voucherPageController.dispose();
    super.dispose();
  }

  // ─────────── COMPUTED PROPERTIES / HELPERS ───────────

  bool get _hasShopSelected => _selectedShopId.isNotEmpty;

  /// Lấy thông tin sale đang hoạt động của sản phẩm
  ProductSaleModel? _getActiveSale(HomeLoaded state, String productId) {
    try {
      return state.productSales.firstWhere(
        (s) => s.productId == productId && s.isActiveNow,
      );
    } catch (_) {
      return null;
    }
  }

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

  /// Bán chạy nhất: đã được backend sort hoặc cubit trả về
  List<ProductModel> _getBestSellers(HomeLoaded state) {
    final source = _hasShopSelected
        ? state.bestSellers.where((p) => p.shopId == _selectedShopId).toList()
        : List<ProductModel>.from(state.bestSellers);
    return source.take(4).toList();
  }

  /// Giảm giá: lấy các sản phẩm đang chạy chương trình khuyến mãi (Active Sale)
  List<ProductModel> _getDiscountedProducts(HomeLoaded state) {
    final source = _hasShopSelected
        ? state.saleProducts.where((p) => p.shopId == _selectedShopId).toList()
        : List<ProductModel>.from(state.saleProducts);
    return source.where((p) => _getActiveSale(state, p.id) != null).toList();
  }

  /// Products filtered for the main grid
  List<ProductModel> _getFilteredProducts(HomeLoaded state) {
    return state.products.where((p) {
      // Filter by shop
      if (_hasShopSelected && p.shopId != _selectedShopId) return false;
      // Filter by category
      if (_hasShopSelected) {
        if (_selectedShopCategoryId != 'all' &&
            p.shopCategoryId != _selectedShopCategoryId) {
          return false;
        }
      } else {
        if (_selectedGlobalCategoryId != 'all' &&
            p.categoryId != _selectedGlobalCategoryId) {
          return false;
        }
      }
      // Filter by search
      if (_searchQuery.isNotEmpty &&
          !p.productName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  // ─────────── BUILD ───────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE67E22)),
          );
        }

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
          final bestSellers = _getBestSellers(state);
          final discountedProducts = _getDiscountedProducts(state);
          final filteredProducts = _getFilteredProducts(state);
          final shopCats = state.shopCategories;

          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().refresh(),
            color: const Color(0xFFE67E22),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Shop Selector
                  _buildShopSelectorSection(state.shops, l10n),
                  const SizedBox(height: 16),

                  // 2. Search Bar
                  _buildSearchBar(l10n),
                  const SizedBox(height: 20),

                  // 3. Voucher Slider
                  if (visibleVouchers.isNotEmpty) ...[
                    _buildVoucherSlider(l10n, visibleVouchers),
                    const SizedBox(height: 24),
                  ],

                  // 4. Bán chạy nhất
                  _buildBestSellersSection(bestSellers, state, l10n),

                  // 5. Đang giảm giá
                  _buildDiscountedSection(discountedProducts, state, l10n),
                  const SizedBox(height: 24),

                  // 6. Category Filter
                  if (_hasShopSelected)
                    _buildShopCategoryFilter(shopCats, l10n)
                  else
                    _buildGlobalCategoryFilter(state.categories, l10n),
                  const SizedBox(height: 20),

                  // 7. Products Grid
                  _buildProductsSection(l10n, filteredProducts, state),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ─────────── SHOP SELECTOR ───────────

  Widget _buildShopSelectorSection(
    List<ShopModel> shops,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                l10n.homeShopBranch,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7F8C8D),
                ),
              ),
              const SizedBox(width: 6),
              if (_hasShopSelected)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedShopId = '';
                      _selectedShopCategoryId = 'all';
                      _selectedGlobalCategoryId = 'all';
                    });
                    context.read<HomeCubit>().loadShopCategories('');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EAE1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.close_rounded,
                          size: 11,
                          color: Color(0xFF7F8C8D),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          l10n.homeDeselect,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: shops.length,
            itemBuilder: (context, idx) {
              final shop = shops[idx];
              final isSelected = _selectedShopId == shop.id;
              return GestureDetector(
                onTap: () {
                  final newShopId = isSelected ? '' : shop.id;
                  setState(() {
                    _selectedShopId = newShopId;
                    _selectedShopCategoryId = 'all';
                    _selectedGlobalCategoryId = 'all';
                  });
                  context.read<HomeCubit>().loadShopCategories(newShopId);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 250,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFDF0E5) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFFD1A9)
                          : const Color(0xFFF1EAE1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x06000000),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          shop.logo,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFFF1EAE1),
                            child: const Icon(
                              Icons.store_rounded,
                              color: Color(0xFFE67E22),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              shop.shopName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFFD35400)
                                    : const Color(0xFF2C3E50),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF1C40F),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  "${shop.rating}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7F8C8D),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.phone_in_talk_rounded,
                                  color: Color(0xFF95A5A6),
                                  size: 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  shop.phone,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF95A5A6),
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
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────── SEARCH BAR ───────────

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE67E22).withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: l10n.homeSearchHint,
            hintStyle: const TextStyle(color: Color(0xFFBDC3C7), fontSize: 13),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFFE67E22),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
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
              Text(
                l10n.homePromoForYou,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(width: 6),
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
        const SizedBox(height: 12),
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
            color: accentColor.withOpacity(0.08),
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
              color: accentColor.withOpacity(0.15),
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

  // ─────────── BÁN CHẠY NHẤT ───────────

  Widget _buildBestSellersSection(
    List<ProductModel> bestSellers,
    HomeLoaded state,
    AppLocalizations l10n,
  ) {
    final label = _hasShopSelected
        ? l10n.homeBestSellersBranch
        : l10n.homeBestSellersGlobal;
    return _buildHorizontalProductsSection(
      label: label,
      iconPath: Assets.icons.hot.path,
      badgeColor: const Color(0xFFE67E22),
      products: bestSellers,
      state: state,
      l10n: l10n,
      showDiscountBadge: true,
    );
  }

  // ─────────── ĐANG GIẢM GIÁ ───────────

  Widget _buildDiscountedSection(
    List<ProductModel> discountedProducts,
    HomeLoaded state,
    AppLocalizations l10n,
  ) {
    const SizedBox(height: 20);
    final label = _hasShopSelected
        ? l10n.homeSalesBranch
        : l10n.homeSalesGlobal;
    return _buildHorizontalProductsSection(
      label: label,
      iconPath: Assets.icons.discount.path,
      badgeColor: const Color(0xFFE74C3C),
      products: discountedProducts,
      state: state,
      l10n: l10n,
      showDiscountBadge: true,
    );
  }

  Widget _buildHorizontalProductsSection({
    required String label,
    required String iconPath,
    required Color badgeColor,
    required List<ProductModel> products,
    required HomeLoaded state,
    required AppLocalizations l10n,
    bool showDiscountBadge = false,
  }) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Image.asset(iconPath, width: 30, height: 30),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              if (!_hasShopSelected) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.homeAllBranches,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: products.length,
            itemBuilder: (context, idx) => _buildHorizontalProductCard(
              products[idx],
              state,
              showDiscountBadge: showDiscountBadge,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalProductCard(
    ProductModel product,
    HomeLoaded state, {
    bool showDiscountBadge = false,
  }) {
    return HorizontalProductCard(
      product: product,
      activeSale: _getActiveSale(state, product.id),
      now: _now,
      showDiscountBadge: showDiscountBadge,
      onTap: () =>
          getx.Get.toNamed(Routes.productDetailPage, arguments: product.id),
    );
  }

  // ─────────── GLOBAL CATEGORY FILTER ───────────

  Widget _buildGlobalCategoryFilter(
    List<CategoryModel> categories,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            l10n.homeCategories,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _buildCategoryChip(
                id: 'all',
                label: l10n.homeAll,
                isSelected: _selectedGlobalCategoryId == 'all',
                onTap: () => setState(() => _selectedGlobalCategoryId = 'all'),
              ),
              ...categories.map(
                (cat) => _buildCategoryChip(
                  id: cat.id,
                  label: cat.categoryName,
                  iconUrl: cat.categoryIcon,
                  isSelected: _selectedGlobalCategoryId == cat.id,
                  onTap: () =>
                      setState(() => _selectedGlobalCategoryId = cat.id),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────── SHOP CATEGORY FILTER ───────────

  Widget _buildShopCategoryFilter(
    List<ShopCategoryModel> shopCats,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            l10n.homeShopMenu,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _buildCategoryChip(
                id: 'all',
                label: l10n.homeAllItems,
                isSelected: _selectedShopCategoryId == 'all',
                onTap: () => setState(() => _selectedShopCategoryId = 'all'),
              ),
              ...shopCats.map(
                (cat) => _buildCategoryChip(
                  id: cat.id,
                  label: cat.categoryName,
                  iconUrl: cat.categoryIcon,
                  isSelected: _selectedShopCategoryId == cat.id,
                  onTap: () => setState(() => _selectedShopCategoryId = cat.id),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String id,
    required String label,
    String? iconUrl,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: EdgeInsets.only(
          left: iconUrl != null ? 6 : 14,
          right: 14,
          top: 6,
          bottom: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE67E22) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFF1EAE1),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE67E22).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconUrl != null) ...[
              ClipOval(
                child: Image.network(
                  iconUrl,
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 26,
                    height: 26,
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : const Color(0xFFF1EAE1),
                    child: const Icon(
                      Icons.image_not_supported_rounded,
                      size: 14,
                      color: Color(0xFFBDC3C7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────── PRODUCTS GRID ───────────

  Widget _buildProductsSection(
    AppLocalizations l10n,
    List<ProductModel> products,
    HomeLoaded state,
  ) {
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Color(0xFFBDC3C7),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.homeNoProductsFound,
                style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: products.length,
        itemBuilder: (context, idx) {
          final product = products[idx];
          return ProductGridCard(
            product: product,
            activeSale: _getActiveSale(state, product.id),
            now: _now,
            onTap: () => getx.Get.toNamed(
              Routes.productDetailPage,
              arguments: product.id,
            ),
          );
        },
      ),
    );
  }
}
