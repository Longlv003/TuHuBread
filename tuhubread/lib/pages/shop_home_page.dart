import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../blocs/home/home_cubit.dart';
import '../blocs/home/home_state.dart';
import '../blocs/cart/cart_cubit.dart';
import '../blocs/cart/cart_state.dart';
import '../gen/assets.gen.dart';
import '../models/category.model.dart';
import '../models/product.model.dart';
import '../models/product_sale.model.dart';
import '../models/shop.model.dart';
import '../helpers/cart_action_helper.dart';
import '../routes/routes.dart';
import '../widgets/horizontal_product_card.dart';
import '../widgets/product_grid_card.dart';

class ShopHomePage extends StatefulWidget {
  const ShopHomePage({super.key});

  @override
  State<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends State<ShopHomePage> {
  late ShopModel _shop;
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  DateTime _now = DateTime.now();
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    final args = getx.Get.arguments as Map<String, dynamic>;
    _shop = args['shop'] as ShopModel;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  ProductSaleModel? _getActiveSale(HomeLoaded state, String productId) {
    try {
      return state.productSales.firstWhere(
        (s) => s.productId == productId && s.isActiveNow,
      );
    } catch (_) {
      return null;
    }
  }

  List<ProductModel> _getBestSellers(HomeLoaded state) {
    return state.bestSellers.where((p) => p.shopId == _shop.id).take(4).toList();
  }

  List<ProductModel> _getDiscountedProducts(HomeLoaded state) {
    return state.saleProducts
        .where((p) => p.shopId == _shop.id && _getActiveSale(state, p.id) != null)
        .toList();
  }

  List<CategoryModel> _getFilteredCategories(HomeLoaded state) {
    final shopCategoryIds = state.products
        .where((p) => p.shopId == _shop.id)
        .map((p) => p.categoryId)
        .toSet();
    return state.categories.where((c) => shopCategoryIds.contains(c.id)).toList();
  }

  List<ProductModel> _getFilteredProducts(HomeLoaded state) {
    return state.products.where((p) {
      final matchShop = p.shopId == _shop.id;
      final matchCat = _selectedCategoryId == 'all' || p.categoryId == _selectedCategoryId;
      final matchSearch = _searchQuery.isEmpty || p.productName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchShop && matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
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
                    const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFE74C3C)),
                    const SizedBox(height: 12),
                    Text(state.error, style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 14)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<HomeCubit>().refresh(),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE67E22)),
                      child: Text(l10n.retryButton),
                    ),
                  ],
                ),
              );
            }

            if (state is HomeLoaded) {
              final bestSellers = _getBestSellers(state);
              final discountedProducts = _getDiscountedProducts(state);
              final filteredProducts = _getFilteredProducts(state);

              return RefreshIndicator(
                onRefresh: () => context.read<HomeCubit>().refresh(),
                color: const Color(0xFFE67E22),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shop Banner with Back Button
                      Stack(
                        children: [
                          Image.network(
                            _shop.banner,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: double.infinity,
                              height: 180,
                              color: const Color(0xFFF1EAE1),
                              child: const Icon(Icons.image, size: 48, color: Color(0xFFBDC3C7)),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.5),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                                onPressed: () => getx.Get.back(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Shop Information Panel
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _shop.logo,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: 64,
                                  height: 64,
                                  color: const Color(0xFFF1EAE1),
                                  child: const Icon(Icons.store, color: Color(0xFFE67E22)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _shop.shopName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Color(0xFFF1C40F), size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        _shop.rating == 99 ? "Chưa có đánh giá" : "${_shop.rating}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7F8C8D),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFE67E22), size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        _shop.phone,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, color: Color(0xFFE67E22), size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _shop.address,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
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

                      const Divider(height: 1, color: Color(0xFFF1EAE1)),
                      const SizedBox(height: 16),

                      // Search bar inside shop
                      _buildSearchBar(l10n),
                      const SizedBox(height: 20),

                      // Best sellers
                      if (bestSellers.isNotEmpty) ...[
                        _buildBestSellersSection(bestSellers, state, l10n),
                        const SizedBox(height: 20),
                      ],

                      // Sales
                      if (discountedProducts.isNotEmpty) ...[
                        _buildDiscountedSection(discountedProducts, state, l10n),
                        const SizedBox(height: 20),
                      ],

                      // Categories
                      _buildCategoryFilter(_getFilteredCategories(state), l10n),
                      const SizedBox(height: 20),

                      // Product Grid
                      _buildProductsSection(l10n, filteredProducts, state),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: BlocBuilder<CartCubit, CartState>(
        builder: (context, cartState) {
          int count = cartState.totalQuantity;
          if (count == 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () {
              getx.Get.offAllNamed(Routes.homePage, arguments: 1);
            },
            backgroundColor: const Color(0xFFE67E22),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_rounded, color: Colors.white),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            ),
            label: const Text(
              "Xem giỏ hàng",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

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
            hintText: "Tìm kiếm món ăn tại cửa hàng...",
            hintStyle: const TextStyle(color: Color(0xFFBDC3C7), fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE67E22)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildBestSellersSection(List<ProductModel> bestSellers, HomeLoaded state, AppLocalizations l10n) {
    return _buildHorizontalProductsSection(
      label: "Bán chạy nhất",
      iconPath: Assets.icons.hot.path,
      badgeColor: const Color(0xFFE67E22),
      products: bestSellers,
      state: state,
      l10n: l10n,
      showDiscountBadge: true,
    );
  }

  Widget _buildDiscountedSection(List<ProductModel> discountedProducts, HomeLoaded state, AppLocalizations l10n) {
    return _buildHorizontalProductsSection(
      label: "Đang giảm giá",
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
              const SizedBox(width: 4),
              Text(
                label,
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

  Widget _buildHorizontalProductCard(ProductModel product, HomeLoaded state, {bool showDiscountBadge = false}) {
    final l10n = AppLocalizations.of(context)!;
    return HorizontalProductCard(
      product: product,
      activeSale: _getActiveSale(state, product.id),
      now: _now,
      showDiscountBadge: showDiscountBadge,
      onTap: () => getx.Get.toNamed(Routes.productDetailPage, arguments: product.id),
      onAddToCart: () => CartActionHelper.quickAddProductWithFeedback(
        context,
        product.id,
        successMessage: l10n.detailAddedToCart,
        failureFallback: l10n.cartAddFailed,
      ),
    );
  }

  Widget _buildCategoryFilter(List<CategoryModel> categories, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            l10n.homeCategories,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
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
                isSelected: _selectedCategoryId == 'all',
                onTap: () => setState(() => _selectedCategoryId = 'all'),
              ),
              ...categories.map(
                (cat) => _buildCategoryChip(
                  id: cat.id,
                  label: cat.categoryName,
                  iconUrl: cat.categoryIcon,
                  isSelected: _selectedCategoryId == cat.id,
                  onTap: () => setState(() => _selectedCategoryId = cat.id),
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
                    color: isSelected ? Colors.white.withOpacity(0.3) : const Color(0xFFF1EAE1),
                    child: const Icon(Icons.image_not_supported_rounded, size: 14, color: Color(0xFFBDC3C7)),
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

  Widget _buildProductsSection(AppLocalizations l10n, List<ProductModel> products, HomeLoaded state) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFBDC3C7)),
              SizedBox(height: 12),
              Text("Không tìm thấy sản phẩm nào", style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 13)),
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
          childAspectRatio: 0.78,
        ),
        itemCount: products.length,
        itemBuilder: (context, idx) {
          final product = products[idx];
          return ProductGridCard(
            product: product,
            activeSale: _getActiveSale(state, product.id),
            now: _now,
            onTap: () => getx.Get.toNamed(Routes.productDetailPage, arguments: product.id),
            onAddToCart: () => CartActionHelper.quickAddProductWithFeedback(
              context,
              product.id,
              successMessage: l10n.detailAddedToCart,
              failureFallback: l10n.cartAddFailed,
            ),
          );
        },
      ),
    );
  }
}
