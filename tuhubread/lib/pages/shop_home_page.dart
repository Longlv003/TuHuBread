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
import '../models/shop.model.dart';
import '../helpers/cart_action_helper.dart';
import '../routes/routes.dart';
import '../widgets/app_network_image.dart';
import '../widgets/horizontal_product_card.dart';
import '../widgets/product_grid_card.dart';
import '../widgets/skeleton.dart';

class ShopHomePage extends StatefulWidget {
  const ShopHomePage({super.key});

  @override
  State<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends State<ShopHomePage> {
  late ShopModel _shop;
  String _selectedCategoryId = 'all';
  String _searchQuery = '';

  /// Chiều cao banner khi mở hết. Khi cuộn quá ngưỡng này, banner thu lại và
  /// thanh tìm kiếm hiện lên trên header (giống ShopeeFood).
  static const double _bannerHeight = 180;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isHeaderCollapsed = false;

  @override
  void initState() {
    super.initState();
    final args = getx.Get.arguments as Map<String, dynamic>;
    _shop = args['shop'] as ShopModel;
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    // Trừ kToolbarHeight vì SliverAppBar luôn ghim lại phần thanh công cụ.
    final collapsed = _scrollController.offset > (_bannerHeight - kToolbarHeight);
    if (collapsed != _isHeaderCollapsed) {
      setState(() => _isHeaderCollapsed = collapsed);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _getBestSellers(HomeLoaded state) {
    return state.bestSellers.where((p) => p.shopId == _shop.id).take(4).toList();
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
            if (state is HomeLoading) return const ProductGridSkeleton();

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
              final filteredProducts = _getFilteredProducts(state);

              return RefreshIndicator(
                onRefresh: () => context.read<HomeCubit>().refresh(),
                color: const Color(0xFFE67E22),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Banner thu gọn dần khi cuộn; cuộn quá banner thì thanh
                    // tìm kiếm hiện lên và ghim lại ở đầu màn hình.
                    SliverAppBar(
                      expandedHeight: _bannerHeight,
                      pinned: true,
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      elevation: 1,
                      automaticallyImplyLeading: false,
                      leading: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: CircleAvatar(
                          backgroundColor: _isHeaderCollapsed
                              ? const Color(0xFFF1EAE1)
                              : Colors.black.withValues(alpha: 0.5),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              color: _isHeaderCollapsed
                                  ? const Color(0xFF2C3E50)
                                  : Colors.white,
                              size: 18,
                            ),
                            onPressed: () => getx.Get.back(),
                          ),
                        ),
                      ),
                      titleSpacing: 0,
                      // Ô tìm kiếm chỉ hiện khi đã cuộn qua banner — lúc
                      // banner đang mở thì ẩn đi để không che ảnh cửa hàng.
                      title: _isHeaderCollapsed
                          ? Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildSearchField(
                                hint: "Tìm món tại ${_shop.shopName}",
                              ),
                            )
                          : null,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            AppNetworkImage(
                              url: _shop.banner,
                              width: double.infinity,
                              fallbackIcon: Icons.image,
                              fallbackIconSize: 48,
                            ),
                            // Lớp tối nhẹ phía trên để ô tìm kiếm và nút quay
                            // lại luôn đọc được dù ảnh banner sáng màu.
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0x59000000), Colors.transparent],
                                  stops: [0.0, 0.45],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                      // Báo ngay đầu trang khi quán đang tạm đóng, để khách
                      // không chọn cả giỏ rồi mới bị chặn lúc đặt hàng.
                      if (!_shop.isOpen) _buildClosedBanner(),
                      // Shop Information Panel
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AppNetworkImage(
                                url: _shop.logo,
                                width: 64,
                                height: 64,
                                fallbackIcon: Icons.store,
                                fallbackIconSize: 24,
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
                                        _shop.rating == null ? "Chưa có đánh giá" : "${_shop.rating}",
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

                      // Best sellers
                      if (bestSellers.isNotEmpty) ...[
                        _buildBestSellersSection(bestSellers, l10n),
                        const SizedBox(height: 20),
                      ],

                      // Categories
                      _buildCategoryFilter(_getFilteredCategories(state), l10n),
                      const SizedBox(height: 20),

                      // Product Grid
                      _buildProductsSection(l10n, filteredProducts),
                      const SizedBox(height: 24),
                      ]),
                    ),
                  ],
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

  /// Ô tìm kiếm duy nhất của trang, nằm trên header. Khi banner đang mở thì
  /// ô nổi trên ảnh (có viền trắng mờ cho dễ nhìn), khi đã cuộn thì đổi sang
  /// nền xám nhạt hoà vào thanh header trắng.
  /// Dải báo quán đang tạm đóng, kèm giờ mở cửa nếu shop có khai báo.
  Widget _buildClosedBanner() {
    final hasHours = _shop.openTime != null && _shop.closeTime != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5C6C0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.storefront_rounded,
              size: 18, color: Color(0xFFC0392B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cửa hàng đang tạm đóng',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC0392B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasHours
                      ? 'Bạn vẫn xem được thực đơn nhưng chưa đặt hàng được. '
                          'Giờ mở cửa: ${_shop.openTime} - ${_shop.closeTime}.'
                      : 'Bạn vẫn xem được thực đơn nhưng chưa đặt hàng được.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFC0392B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({required String hint}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: _isHeaderCollapsed ? const Color(0xFFF4F5F7) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isHeaderCollapsed
              ? const Color(0xFFF1EAE1)
              : Colors.white.withValues(alpha: 0.9),
        ),
        boxShadow: _isHeaderCollapsed
            ? null
            : const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBDC3C7), fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFE67E22),
            size: 20,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    FocusScope.of(context).unfocus();
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
          suffixIconConstraints: const BoxConstraints(minWidth: 36),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildBestSellersSection(List<ProductModel> bestSellers, AppLocalizations l10n) {
    return _buildHorizontalProductsSection(
      label: "Bán chạy nhất",
      iconPath: Assets.icons.hot.path,
      badgeColor: const Color(0xFFE67E22),
      products: bestSellers,
      l10n: l10n,
    );
  }

  Widget _buildHorizontalProductsSection({
    required String label,
    required String iconPath,
    required Color badgeColor,
    required List<ProductModel> products,
    required AppLocalizations l10n,
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
            itemBuilder: (context, idx) => _buildHorizontalProductCard(products[idx]),
          ),
        ),
      ],
    );
  }

  /// Thêm món vào giỏ — chặn ngay tại app khi quán đang đóng, kèm giải thích
  /// ngắn. (Server vẫn chặn lần nữa lúc đặt hàng, đây chỉ là lớp cho êm tay.)
  void _addToCart(ProductModel product) {
    if (!_shop.isOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_shop.shopName} đang tạm đóng cửa'),
          backgroundColor: const Color(0xFFE74C3C),
        ),
      );
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    CartActionHelper.quickAddProductWithFeedback(
      context,
      product.id,
      successMessage: l10n.detailAddedToCart,
      failureFallback: l10n.cartAddFailed,
    );
  }

  Widget _buildHorizontalProductCard(ProductModel product) {
    return HorizontalProductCard(
      product: product,
      onTap: () => getx.Get.toNamed(Routes.productDetailPage, arguments: product.id),
      onAddToCart: () => _addToCart(product),
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
                child: AppNetworkImage(
                  url: iconUrl,
                  width: 26,
                  height: 26,
                  fallbackIcon: Icons.image_not_supported_rounded,
                  fallbackIconSize: 14,
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

  Widget _buildProductsSection(AppLocalizations l10n, List<ProductModel> products) {
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
          childAspectRatio: 0.68,
        ),
        itemCount: products.length,
        itemBuilder: (context, idx) {
          final product = products[idx];
          return ProductGridCard(
            product: product,
            onTap: () => getx.Get.toNamed(Routes.productDetailPage, arguments: product.id),
            onAddToCart: () => _addToCart(product),
          );
        },
      ),
    );
  }
}
