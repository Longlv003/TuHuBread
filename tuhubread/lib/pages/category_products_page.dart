import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import 'package:tuhubread/l10n/app_localizations.dart';

import '../helpers/cart_action_helper.dart';
import '../models/category.model.dart';
import '../models/product.model.dart';
import '../models/shop.model.dart';
import '../routes/routes.dart';
import '../widgets/product_grid_card.dart';

/// Cách sắp xếp sản phẩm trong trang danh mục.
enum _ProductSort { nearby, bestSelling, rating }

/// Trang liệt kê sản phẩm thuộc 1 danh mục, chỉ lấy từ các cửa hàng trong
/// bán kính giao hàng (danh sách shop được truyền vào đã do backend lọc theo
/// bán kính 10km).
class CategoryProductsPage extends StatefulWidget {
  final CategoryModel category;
  final List<ProductModel> products;
  final List<ShopModel> nearbyShops;

  const CategoryProductsPage({
    super.key,
    required this.category,
    required this.products,
    required this.nearbyShops,
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  _ProductSort _sort = _ProductSort.nearby;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, ShopModel> get _shopById => {
        for (final s in widget.nearbyShops) s.id: s,
      };

  List<ProductModel> get _visibleProducts {
    final shops = _shopById;
    var list = widget.products
        .where((p) => p.categoryId == widget.category.id)
        // Chỉ giữ sản phẩm của cửa hàng nằm trong bán kính giao hàng.
        .where((p) => shops.containsKey(p.shopId))
        .toList();

    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((p) => p.productName.toLowerCase().contains(q)).toList();
    }

    switch (_sort) {
      case _ProductSort.nearby:
        list.sort((a, b) {
          final da = shops[a.shopId]?.distanceKm ?? double.infinity;
          final db = shops[b.shopId]?.distanceKm ?? double.infinity;
          return da.compareTo(db);
        });
      case _ProductSort.bestSelling:
        list.sort((a, b) => b.salesCount.compareTo(a.salesCount));
      case _ProductSort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final products = _visibleProducts;
    final shops = _shopById;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.category.categoryName,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50)),
          onPressed: () => getx.Get.back(),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: l10n.categorySearchHint(widget.category.categoryName),
                    hintStyle: const TextStyle(color: Color(0xFFBDC3C7), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFFE67E22), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF4F5F7),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildSortTabs(l10n),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1EAE1)),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: Color(0xFFBDC3C7)),
                          const SizedBox(height: 12),
                          Text(
                            l10n.categoryEmptyNearby,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
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
                        shopName: shops[product.shopId]?.shopName,
                        onTap: () => getx.Get.toNamed(
                          Routes.productDetailPage,
                          arguments: product.id,
                        ),
                        onAddToCart: () =>
                            CartActionHelper.quickAddProductWithFeedback(
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
      ),
    );
  }

  Widget _buildSortTabs(AppLocalizations l10n) {
    final labels = {
      _ProductSort.nearby: l10n.filterNearMe,
      _ProductSort.bestSelling: l10n.filterBestSelling,
      _ProductSort.rating: l10n.filterRating,
    };

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: _ProductSort.values.map((sort) {
          final isSelected = _sort == sort;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _sort = sort),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[sort]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
}
