import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tuhubread/l10n/app_localizations.dart';

import '../../gen/assets.gen.dart';
import '../../models/category.model.dart';
import '../../models/product.model.dart';
import '../../models/product_sale.model.dart';
import '../../models/shop.model.dart';
import '../../models/shop_category.model.dart';
import '../../models/user.model.dart';
import '../../models/voucher.model.dart';
import '../../utils/currency_formatter.dart';

class HomeTab extends StatefulWidget {
  final UserModel user;

  const HomeTab({super.key, required this.user});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
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

  // ─────────── MOCK DATABASE DATA ───────────

  final List<ShopModel> _shops = [
    ShopModel(
      id: 'shop_001',
      shopName: 'Bánh Mì TuHu - Lê Duẩn',
      phone: '0987654321',
      avatar:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=100',
      banner:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600',
      rating: 4.9,
      status: 'active',
    ),
    ShopModel(
      id: 'shop_002',
      shopName: 'Bánh Mì TuHu - Nguyễn Văn Linh',
      phone: '0912345678',
      avatar: 'https://images.unsplash.com/photo-1549611016-3a70d82b5040?w=100',
      banner: 'https://images.unsplash.com/photo-1549611016-3a70d82b5040?w=600',
      rating: 4.7,
      status: 'active',
    ),
  ];

  // Global categories (hiện trước khi chọn shop)
  final List<CategoryModel> _globalCategories = [
    CategoryModel(
      id: 'cat_bread',
      categoryName: 'Bánh Mì',
      categorySlug: 'banh-mi',
      categoryIcon:
          'http://localhost:3000/images/categories/cat_bread.jpg',
      status: 'active',
    ),
    CategoryModel(
      id: 'cat_drink',
      categoryName: 'Nước Uống',
      categorySlug: 'nuoc-uong',
      categoryIcon:
          'http://localhost:3000/images/categories/cat_drink.jpg',
      status: 'active',
    ),
    CategoryModel(
      id: 'cat_combo',
      categoryName: 'Combo',
      categorySlug: 'combo',
      categoryIcon:
          'http://localhost:3000/images/categories/cat_combo.jpg',
      status: 'active',
    ),
  ];

  // Shop categories (hiện sau khi chọn shop)
  final List<ShopCategoryModel> _shopCategories = [
    // Shop 1
    ShopCategoryModel(
      id: 'scat_best_1',
      shopId: 'shop_001',
      categoryName: 'Món Bán Chạy',
      categorySlug: 'mon-ban-chay',
      categoryIcon:
          'http://localhost:3000/images/categories/scat_best.jpg',
      sortOrder: 1,
      status: 'active',
    ),
    ShopCategoryModel(
      id: 'scat_trad_1',
      shopId: 'shop_001',
      categoryName: 'Bánh Mì Truyền Thống',
      categorySlug: 'banh-mi-truyen-thong',
      categoryIcon:
          'http://localhost:3000/images/categories/cat_bread.jpg',
      sortOrder: 2,
      status: 'active',
    ),
    ShopCategoryModel(
      id: 'scat_drink_1',
      shopId: 'shop_001',
      categoryName: 'Trà & Giải Khát',
      categorySlug: 'tra-giai-khat',
      categoryIcon:
          'http://localhost:3000/images/categories/cat_drink.jpg',
      sortOrder: 3,
      status: 'active',
    ),
    // Shop 2
    ShopCategoryModel(
      id: 'scat_combo_2',
      shopId: 'shop_002',
      categoryName: 'Combo Tiết Kiệm',
      categorySlug: 'combo-tiet-kiem',
      categoryIcon:
          'http://localhost:3000/images/categories/cat_combo.jpg',
      sortOrder: 1,
      status: 'active',
    ),
    ShopCategoryModel(
      id: 'scat_chicken_2',
      shopId: 'shop_002',
      categoryName: 'Bánh Mì Gà Xé',
      categorySlug: 'banh-mi-ga-xe',
      categoryIcon:
          'http://localhost:3000/images/categories/scat_chicken.jpg',
      sortOrder: 2,
      status: 'active',
    ),
  ];

  final List<ProductModel> _products = [
    // Shop 1
    ProductModel(
      id: 'prod_special',
      shopId: 'shop_001',
      categoryId: 'cat_bread',
      shopCategoryId: 'scat_best_1',
      productName: 'Bánh Mì TuHu Đặc Biệt',
      productSlug: 'banh-mi-tuhu-dac-biet',
      price: 25000, // Giá gốc chuẩn chưa sale
      image:
          'http://localhost:3000/images/products/prod_special.jpg',
      description:
          'Nhân pate thơm béo, chả lụa thịt nguội, xúc xích và rau dưa tươi mát kèm nước sốt đặc trưng.',
      rating: 5.0,
      salesCount: 154,
      status: 'active',
    ),
    ProductModel(
      id: 'prod_char_siu',
      shopId: 'shop_001',
      categoryId: 'cat_bread',
      shopCategoryId: 'scat_trad_1',
      productName: 'Bánh Mì Thịt Xá Xíu',
      productSlug: 'banh-mi-thit-xa-xiu',
      price: 20000,
      image:
          'http://localhost:3000/images/products/prod_char_siu.jpg',
      description:
          'Thịt xá xíu đậm vị, nướng lò mật ong ngọt dịu kết hợp cùng dưa chua và rau thơm cay nồng.',
      rating: 4.8,
      salesCount: 180, // Tăng lên để lọt vào Best Sellers nhưng không có sale
      status: 'active',
    ),
    ProductModel(
      id: 'prod_thai_tea',
      shopId: 'shop_001',
      categoryId: 'cat_drink',
      shopCategoryId: 'scat_drink_1',
      productName: 'Trà Sữa Thái Xanh Thạch',
      productSlug: 'tra-sua-thai-xanh-thach',
      price: 22000, // Giá gốc chuẩn chưa sale
      image:
          'http://localhost:3000/images/products/prod_thai_tea.jpg',
      description:
          'Trà Thái xanh béo ngậy sữa đặc, vị chát nhẹ ngọt mát kèm thạch lá dứa giòn sần sật cực đã.',
      rating: 4.9,
      salesCount: 248,
      status: 'active',
    ),
    // Shop 2
    ProductModel(
      id: 'prod_combo_tuhu',
      shopId: 'shop_002',
      categoryId: 'cat_combo',
      shopCategoryId: 'scat_combo_2',
      productName: 'Combo Bánh Mì + Trà Sữa',
      productSlug: 'combo-banh-mi-tra-sua',
      price: 38000, // Giá gốc chuẩn chưa sale
      image:
          'http://localhost:3000/images/products/prod_combo_tuhu.jpg',
      description:
          'Tiết kiệm hơn với combo gồm 1 bánh mì TuHu đặc biệt và 1 trà sữa Thái xanh mát lạnh.',
      rating: 4.9,
      salesCount: 185,
      status: 'active',
    ),
    ProductModel(
      id: 'prod_chicken_shred',
      shopId: 'shop_002',
      categoryId: 'cat_bread',
      shopCategoryId: 'scat_chicken_2',
      productName: 'Bánh Mì Gà Xé Bơ Tỏi',
      productSlug: 'banh-mi-ga-xe-bo-toi',
      price: 19000,
      image:
          'http://localhost:3000/images/products/prod_chicken_shred.jpg',
      description:
          'Thịt ức gà xé cay, xào tỏi thơm nức nở hòa quyện bơ vàng béo mịn bọc trong bánh mì giòn tan.',
      rating: 4.7,
      salesCount: 140, // Tăng lên để lọt vào Best Sellers nhưng không có sale
      status: 'active',
    ),
    ProductModel(
      id: 'prod_pate_special',
      shopId: 'shop_001',
      categoryId: 'cat_bread',
      shopCategoryId: 'scat_trad_1',
      productName: 'Bánh Mì Pate Đặc Biệt',
      productSlug: 'banh-mi-pate-dac-biet',
      price: 19000, // Giá gốc chuẩn chưa sale
      image:
          'http://localhost:3000/images/products/prod_pate_special.jpg',
      description:
          'Pate gan mịn thơm, kẹp chả chiên giòn rụm, dưa leo tươi mát — vị Sài Gòn cổ điển.',
      rating: 4.6,
      salesCount: 110,
      status: 'active',
    ),
  ];

  // Danh sách các đợt sale sản phẩm đang chạy
  final List<ProductSaleModel> _productSales = [
    ProductSaleModel(
      id: 'sale_001',
      productId: 'prod_special',
      saleName: 'Flash Sale Giờ Vàng',
      salePrice: 18000, // Giảm từ 25k -> 18k
      saleLimit: 50,
      soldQuantity: 12,
      startDate: DateTime.now().subtract(const Duration(hours: 1)),
      endDate: DateTime.now().add(
        const Duration(hours: 2),
      ), // Kết thúc sau 2 tiếng
      status: 'active',
    ),
    ProductSaleModel(
      id: 'sale_002',
      productId: 'prod_thai_tea',
      saleName: 'Giải Nhiệt Mùa Hè',
      salePrice: 16000, // Giảm từ 22k -> 16k
      saleLimit: 100,
      soldQuantity: 45,
      startDate: DateTime.now().subtract(const Duration(hours: 2)),
      endDate: DateTime.now().add(
        const Duration(hours: 4),
      ), // Kết thúc sau 4 tiếng
      status: 'active',
    ),
    ProductSaleModel(
      id: 'sale_003',
      productId: 'prod_combo_tuhu',
      saleName: 'Combo Tiết Kiệm',
      salePrice: 30000, // Giảm từ 38k -> 30k
      saleLimit: null,
      soldQuantity: 20,
      startDate: DateTime.now().subtract(const Duration(hours: 1)),
      endDate: DateTime.now().add(const Duration(hours: 5)),
      status: 'active',
    ),
    ProductSaleModel(
      id: 'sale_004',
      productId: 'prod_pate_special',
      saleName: 'Ưu Đãi Bánh Mì Pate',
      salePrice: 15000, // Giảm từ 19k -> 15k
      saleLimit: 30,
      soldQuantity: 10,
      startDate: DateTime.now().subtract(const Duration(hours: 3)),
      endDate: DateTime.now().add(const Duration(hours: 1)),
      status: 'active',
    ),
  ];

  final List<VoucherModel> _vouchers = [
    VoucherModel(
      id: 'vouch_welcome',
      voucherCode: 'TUHUWELCOME',
      voucherName: 'Chào mừng thành viên mới',
      voucherType: 'platform',
      discountType: 'amount',
      discountValue: 10000,
      minOrderAmount: 30000,
      maxDiscountAmount: 10000,
      claimLimit: null,
      claimedCount: 52,
      usageLimit: null,
      usedCount: 52,
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 30)),
      status: 'active',
    ),
    VoucherModel(
      id: 'vouch_flash',
      voucherCode: 'TUHU20FLASH',
      voucherName: 'Flash Sale - Giảm 20%',
      voucherType: 'shop',
      discountType: 'percent',
      discountValue: 20,
      minOrderAmount: 40000,
      maxDiscountAmount: 15000,
      claimLimit: 10,
      claimedCount: 7,
      usageLimit: null,
      usedCount: 3,
      startDate: DateTime.now().subtract(const Duration(hours: 1)),
      endDate: DateTime.now().add(const Duration(hours: 2)),
      status: 'active',
    ),
    // Voucher đã hết mã — sẽ bị ẩn tự động
    VoucherModel(
      id: 'vouch_expired',
      voucherCode: 'TUHUSOLD',
      voucherName: 'Đã hết mã',
      voucherType: 'shop',
      discountType: 'amount',
      discountValue: 5000,
      minOrderAmount: 20000,
      maxDiscountAmount: 5000,
      claimLimit: 5,
      claimedCount: 5, // hết mã
      usageLimit: null,
      usedCount: 5,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(hours: 1)),
      status: 'active',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });

    // Auto-scroll Voucher Slide mỗi 3 giây
    _voucherSliderTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_visibleVouchers.isEmpty) return;
      if (_voucherPageController.hasClients) {
        int nextPage = _voucherPageController.page!.toInt() + 1;
        if (nextPage >= _visibleVouchers.length) {
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

  // ─────────── COMPUTED PROPERTIES ───────────

  bool get _hasShopSelected => _selectedShopId.isNotEmpty;

  /// Lấy thông tin sale đang hoạt động của sản phẩm
  ProductSaleModel? _getActiveSale(String productId) {
    try {
      return _productSales.firstWhere(
        (s) => s.productId == productId && s.isActiveNow,
      );
    } catch (_) {
      return null;
    }
  }

  /// Vouchers visible: ẩn đã save + ẩn hết mã
  List<VoucherModel> get _visibleVouchers => _vouchers.where((v) {
    final isSaved = _savedVoucherIds.contains(v.id);
    final isFull = v.claimLimit != null && v.claimedCount >= v.claimLimit!;
    return !isSaved && !isFull;
  }).toList();

  /// Bán chạy nhất: top 4 theo salesCount
  /// — Global: tất cả sản phẩm; Shop: chỉ sản phẩm của shop đó
  List<ProductModel> get _bestSellers {
    final source = _hasShopSelected
        ? _products.where((p) => p.shopId == _selectedShopId).toList()
        : List<ProductModel>.from(_products);
    source.sort((a, b) => b.salesCount.compareTo(a.salesCount));
    return source.take(4).toList();
  }

  /// Giảm giá: lấy các sản phẩm đang chạy chương trình khuyến mãi (Active Sale)
  /// — Global: tất cả; Shop: chỉ của shop
  List<ProductModel> get _discountedProducts {
    final source = _hasShopSelected
        ? _products.where((p) => p.shopId == _selectedShopId).toList()
        : List<ProductModel>.from(_products);
    return source.where((p) => _getActiveSale(p.id) != null).toList();
  }

  /// Products filtered for the main grid
  List<ProductModel> get _filteredProducts {
    return _products.where((p) {
      // Filter by shop
      if (_hasShopSelected && p.shopId != _selectedShopId) return false;
      // Filter by category
      if (_hasShopSelected) {
        if (_selectedShopCategoryId != 'all' &&
            p.shopCategoryId != _selectedShopCategoryId)
          return false;
      } else {
        if (_selectedGlobalCategoryId != 'all' &&
            p.categoryId != _selectedGlobalCategoryId)
          return false;
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
    final shopCats = _shopCategories
        .where((sc) => sc.shopId == _selectedShopId)
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Shop Selector
          _buildShopSelectorSection(),
          const SizedBox(height: 16),

          // 2. Search Bar
          _buildSearchBar(l10n),
          const SizedBox(height: 20),

          // 3. Voucher Slider (ẩn saved + hết mã)
          if (_visibleVouchers.isNotEmpty) ...[
            _buildVoucherSlider(l10n),
            const SizedBox(height: 24),
          ],

          // 4. Bán chạy nhất (global hoặc theo shop)
          _buildBestSellersSection(),
          const SizedBox(height: 20),

          // 5. Đang giảm giá (global hoặc theo shop)
          _buildDiscountedSection(),
          const SizedBox(height: 24),

          // 6. Category Filter:
          //    - Chưa chọn shop → globalCategory
          //    - Đã chọn shop → shopCategory
          if (_hasShopSelected)
            _buildShopCategoryFilter(shopCats)
          else
            _buildGlobalCategoryFilter(),
          const SizedBox(height: 20),

          // 7. Products Grid
          _buildProductsSection(l10n, _filteredProducts),
        ],
      ),
    );
  }

  // ─────────── SHOP SELECTOR ───────────

  Widget _buildShopSelectorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Text(
                "Chi nhánh cửa hàng",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7F8C8D),
                ),
              ),
              const SizedBox(width: 6),
              if (_hasShopSelected)
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedShopId = '';
                    _selectedShopCategoryId = 'all';
                    _selectedGlobalCategoryId = 'all';
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EAE1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 11,
                          color: Color(0xFF7F8C8D),
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Bỏ chọn',
                          style: TextStyle(
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
            itemCount: _shops.length,
            itemBuilder: (context, idx) {
              final shop = _shops[idx];
              final isSelected = _selectedShopId == shop.id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedShopId = isSelected ? '' : shop.id;
                    _selectedShopCategoryId = 'all';
                    _selectedGlobalCategoryId = 'all';
                  });
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
                          shop.avatar,
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
          decoration: const InputDecoration(
            hintText: "Tìm bánh mì, đồ uống...",
            hintStyle: TextStyle(color: Color(0xFFBDC3C7), fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: Color(0xFFE67E22)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ─────────── VOUCHER SLIDER ───────────

  Widget _buildVoucherSlider(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Text(
                "Khuyến mãi dành cho bạn",
                style: TextStyle(
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
                  "${_visibleVouchers.length}",
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
          height: 88, // Chiều cao ngắn lại
          child: PageView.builder(
            controller: _voucherPageController,
            physics: const BouncingScrollPhysics(),
            itemCount: _visibleVouchers.length,
            itemBuilder: (context, idx) =>
                _buildVoucherCard(_visibleVouchers[idx]),
          ),
        ),
      ],
    );
  }

  String _formatCountdown(Duration d) {
    if (d.isNegative) return 'Hết hạn';
    if (d.inDays >= 1) return '${d.inDays}n ${d.inHours % 24}g';
    if (d.inHours >= 1) {
      return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Widget _buildVoucherCard(VoucherModel voucher) {
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
            child: Icon(Icons.confirmation_num_rounded, color: accentColor, size: 20),
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
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FLASH',
                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isPercent
                      ? 'Giảm ${voucher.discountValue.toInt()}% • Tối đa ${CurrencyFormatter.formatVND(voucher.maxDiscountAmount ?? 0)}'
                      : 'Giảm ${CurrencyFormatter.formatVND(voucher.discountValue)} • Đơn từ ${CurrencyFormatter.formatVND(voucher.minOrderAmount)}',
                  style: const TextStyle(color: Color(0xFF555555), fontSize: 10),
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
                          ? 'Đã hết hạn'
                          : _formatCountdown(remaining),
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
                            ? 'Hết mã'
                            : 'Còn ${voucher.claimLimit! - voucher.claimedCount} mã',
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã lưu mã "${voucher.voucherCode}" vào ví!',
                        ),
                        backgroundColor: const Color(0xFF27AE60),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
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
                    ? 'Hết mã'
                    : isSaved
                    ? 'Đã lưu'
                    : 'Lưu mã',
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

  Widget _buildBestSellersSection() {
    final label = _hasShopSelected
        ? 'Bán chạy tại chi nhánh'
        : 'Bán chạy toàn hệ thống';
    return _buildHorizontalProductsSection(
      label: label,
      iconPath: Assets.icons.hot.path,
      badgeColor: const Color(0xFFE67E22),
      products: _bestSellers,
    );
  }

  // ─────────── ĐANG GIẢM GIÁ ───────────

  Widget _buildDiscountedSection() {
    final label = _hasShopSelected
        ? 'Đang giảm giá tại chi nhánh'
        : 'Đang giảm giá toàn hệ thống';
    return _buildHorizontalProductsSection(
      label: label,
      iconPath: Assets.icons.discount.path,
      badgeColor: const Color(0xFFE74C3C),
      products: _discountedProducts,
      showDiscountBadge: true,
    );
  }

  Widget _buildHorizontalProductsSection({
    required String label,
    required String iconPath,
    required Color badgeColor,
    required List<ProductModel> products,
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
                    'Tất cả chi nhánh',
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
              showDiscountBadge: showDiscountBadge,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalProductCard(
    ProductModel product, {
    bool showDiscountBadge = false,
  }) {
    final activeSale = _getActiveSale(product.id);
    final hasSale = activeSale != null;
    final displayPrice = hasSale ? activeSale.salePrice : product.price;

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x08000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  product.image,
                  height: 100,
                  width: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 100,
                    width: 150,
                    color: const Color(0xFFF1EAE1),
                    child: const Icon(
                      Icons.bakery_dining,
                      color: Color(0xFFE67E22),
                      size: 30,
                    ),
                  ),
                ),
              ),
              if (hasSale)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SALE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF1C40F),
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        "${product.rating}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Đếm ngược countdown cho đợt sale của sản phẩm
              if (hasSale)
                Positioned(
                  bottom: 4,
                  left: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Colors.white,
                          size: 9,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatCountdown(activeSale.endDate.difference(_now)),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF7F8C8D),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasSale)
                            Text(
                              CurrencyFormatter.formatVND(product.price),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFFBDC3C7),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            CurrencyFormatter.formatVND(displayPrice),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE67E22),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE67E22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── GLOBAL CATEGORY FILTER ───────────

  Widget _buildGlobalCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Danh mục",
            style: TextStyle(
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
                label: 'Tất cả',
                isSelected: _selectedGlobalCategoryId == 'all',
                onTap: () => setState(() => _selectedGlobalCategoryId = 'all'),
              ),
              ..._globalCategories.map(
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

  Widget _buildShopCategoryFilter(List<ShopCategoryModel> shopCats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Thực đơn của cửa hàng",
            style: TextStyle(
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
                label: 'Tất cả món',
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
  ) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Color(0xFFBDC3C7),
              ),
              SizedBox(height: 12),
              Text(
                "Không tìm thấy món phù hợp",
                style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 13),
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
          final activeSale = _getActiveSale(product.id);
          final hasSale = activeSale != null;
          final displayPrice = hasSale ? activeSale.salePrice : product.price;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x0A000000),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Image.network(
                        product.image,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 110,
                          color: const Color(0xFFF1EAE1),
                          child: const Icon(
                            Icons.bakery_dining,
                            color: Color(0xFFE67E22),
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    if (hasSale)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE74C3C),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SALE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Countdown timer overlay for main grid items
                    if (hasSale)
                      Positioned(
                        bottom: 4,
                        left: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.white,
                                size: 9,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _formatCountdown(
                                  activeSale.endDate.difference(_now),
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.description,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF7F8C8D),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF1C40F),
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "${product.rating}",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Đã bán ${product.salesCount}",
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFFBDC3C7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasSale)
                                  Text(
                                    CurrencyFormatter.formatVND(product.price),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFBDC3C7),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  CurrencyFormatter.formatVND(displayPrice),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE67E22),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE67E22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
