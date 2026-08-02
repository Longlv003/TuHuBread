import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuhubread/l10n/app_localizations.dart';

import '../blocs/cart/cart_cubit.dart';
import '../blocs/product_detail/product_detail_cubit.dart';
import '../blocs/product_detail/product_detail_state.dart';
import '../core/result.dart';
import '../di.dart';
import '../models/cart_item.model.dart';
import '../models/product_detail.model.dart';
import '../models/product_variant.model.dart';
import '../models/shop.model.dart';
import '../repositories/home_repository.dart';
import '../utils/cart_price_calculator.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/size_select_bottom_sheet.dart';

/// Helper thêm sản phẩm hiện tại vào giỏ hàng mà không cần sửa logic ProductDetailCubit.
class CartActionHelper {
  CartActionHelper._();

  static Future<bool> addCurrentProductToCart(BuildContext context) async {
    final detailState = context.read<ProductDetailCubit>().state;
    if (detailState is! ProductDetailLoaded) return false;

    final cubit = getIt<CartCubit>();
    final detail = detailState.productDetail;
    final variant = detailState.selectedVariant;
    final optionIds = detailState.selectedOptionIds;

    final canProceed = await _ensureSameShop(
      context,
      cubit,
      shopId: detail.shopId,
      shopName: detail.shop?.shopName,
      productId: detail.id,
      variantId: variant.id,
      optionIds: optionIds.toList(),
      quantity: detailState.quantity,
    );
    if (!canProceed) return false;
    if (!context.mounted) return false;

    final result = await cubit.addFromProductDetail(detailState);
    return result is Success<List<CartItemModel>>;
  }

  /// Thêm nhanh từ danh sách (Home, gợi ý trong giỏ hàng...): nếu sản phẩm
  /// chỉ có một phiên bản thì thêm thẳng, ngược lại mở bottom sheet cho
  /// người dùng chọn size trước khi thêm vào giỏ.
  static Future<void> quickAddProductWithFeedback(
    BuildContext context,
    String productId, {
    required String successMessage,
    required String failureFallback,
  }) async {
    final repository = getIt<HomeRepository>();
    final res = await repository.fetchProductDetail(productId);
    if (!context.mounted) return;

    if (res is Failure<ProductDetailModel>) {
      _showSnackBar(context, false, res.errorOrNull ?? failureFallback);
      return;
    }

    final detail = (res as Success<ProductDetailModel>).data;
    if (detail.variants.isEmpty) {
      _showSnackBar(context, false, 'Sản phẩm chưa có phiên bản bán ra');
      return;
    }

    ProductVariantModel variant;
    Set<String> selectedOptions = {};
    int quantity = 1;

    if (detail.variants.length == 1 && detail.options.isEmpty) {
      variant = detail.variants.first;
    } else {
      final picked = await showSizeSelectBottomSheet(context, detail);
      if (picked == null) return;
      if (!context.mounted) return;
      variant = picked.variant;
      selectedOptions = picked.selectedOptionIds;
      quantity = picked.quantity;
    }

    final cubit = getIt<CartCubit>();
    final canProceed = await _ensureSameShop(
      context,
      cubit,
      shopId: detail.shopId,
      shopName: detail.shop?.shopName,
      productId: detail.id,
      variantId: variant.id,
      optionIds: selectedOptions.toList(),
      quantity: quantity,
    );
    if (!canProceed) return;
    if (!context.mounted) return;

    final unitPrice = CartPriceCalculator.calculateUnitPrice(
      detail,
      variant,
      selectedOptions,
    );

    final result = await cubit.addFromProductDetail(
      ProductDetailLoaded(
        productDetail: detail,
        selectedVariant: variant,
        selectedOptionIds: selectedOptions,
        quantity: quantity,
        totalPrice: unitPrice * quantity,
      ),
    );
    if (!context.mounted) return;

    if (result is Success<List<CartItemModel>>) {
      _showSnackBar(context, true, successMessage);
    } else if (result is Failure<List<CartItemModel>>) {
      _showSnackBar(context, false, result.message);
    }
  }

  /// Giỏ hàng chỉ được chứa sản phẩm của 1 chi nhánh (giống Grab/Shopee Food).
  /// Nếu giỏ đang có sản phẩm của chi nhánh khác [shopId], hỏi xác nhận chuyển
  /// shop hoặc hủy. Trả về true nếu không có xung đột và có thể tiếp tục thêm bình thường.
  static Future<bool> _ensureSameShop(
    BuildContext context,
    CartCubit cubit, {
    required String shopId,
    String? shopName,
    required String productId,
    required String variantId,
    required List<String> optionIds,
    required int quantity,
  }) async {
    final items = cubit.state.items;
    if (items.isEmpty) return true;
    if (items.first.shopId == shopId) return true;

    final confirmed = await AppConfirmDialog.show(
      context,
      type: ConfirmDialogType.warning,
      title: "Trùng sản phẩm shop khác",
      description: "Giỏ hàng của bạn đang chứa sản phẩm của cửa hàng khác.\n\nBạn có muốn tự động tìm cửa hàng bán tất cả các sản phẩm này để chuyển đổi không?",
      confirmTitle: "Tìm cửa hàng",
      cancelTitle: "Hủy",
    );
    if (confirmed != true) return false;
    if (!context.mounted) return false;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE67E22)),
      ),
    );

    final candidatesRes = await cubit.getSwitchShopOptions(productId: productId);
    
    if (context.mounted) {
      Navigator.pop(context); // Dismiss loading
    }
    if (!context.mounted) return false;

    if (candidatesRes is Failure) {
      await AppConfirmDialog.show(
        context,
        type: ConfirmDialogType.warning,
        title: "Không thể chuyển đổi",
        description: "${(candidatesRes as Failure).errorOrNull ?? "Không có cửa hàng nào có đầy đủ sản phẩm."}\n\nNếu bạn vẫn muốn đặt sản phẩm này, vui lòng thanh toán đơn hàng đang có trong giỏ hàng trước, sau đó quay lại đặt mua sản phẩm mới.",
        confirmTitle: "Đóng",
        cancelTitle: "",
      );
      return false;
    }

    final shops = (candidatesRes as Success<List<ShopModel>>).data;
    if (shops.isEmpty) {
      await AppConfirmDialog.show(
        context,
        type: ConfirmDialogType.warning,
        title: "Không thể chuyển đổi",
        description: "Không có cửa hàng nào khác bán đồng thời tất cả sản phẩm trong giỏ hàng.\n\nNếu bạn vẫn muốn đặt sản phẩm này, vui lòng thanh toán đơn hàng đang có trong giỏ hàng trước, sau đó quay lại chọn mua sản phẩm mới.",
        confirmTitle: "Đóng",
        cancelTitle: "",
      );
      return false;
    }

    // Show shop selection dialog
    final selectedShop = await showDialog<ShopModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Chọn cửa hàng mới",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: shops.length,
            itemBuilder: (context, idx) {
              final shop = shops[idx];
              return GestureDetector(
                onTap: () => Navigator.pop(context, shop),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF1EAE1),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          shop.logo,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 50,
                            height: 50,
                            color: const Color(0xFFF1EAE1),
                            child: const Icon(
                              Icons.store_rounded,
                              color: Color(0xFFE67E22),
                            ),
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
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF1C40F),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  shop.rating == 99 ? "Chưa có đánh giá" : "${shop.rating}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7F8C8D),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.phone_in_talk_rounded,
                                  color: Color(0xFF95A5A6),
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  shop.phone,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF7F8C8D),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              shop.address,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF95A5A6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Color(0xFF7F8C8D))),
          ),
        ],
      ),
    );

    if (selectedShop == null) return false;
    if (!context.mounted) return false;

    // Show loading for switch confirmation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE67E22)),
      ),
    );

    final switchRes = await cubit.switchShop(
      shopId: selectedShop.id,
      productId: productId,
      variantId: variantId,
      optionIds: optionIds,
      quantity: quantity,
    );

    if (context.mounted) {
      Navigator.pop(context); // Dismiss loading
    }
    if (!context.mounted) return false;

    if (switchRes is Success) {
      _showSnackBar(context, true, "Chuyển đổi cửa hàng và thêm sản phẩm thành công!");
    } else {
      _showSnackBar(context, false, (switchRes as Failure).message);
    }
    return false;
  }

  /// Xây dựng 1 [CartItemModel] cục bộ (không lưu server) từ lựa chọn hiện
  /// tại trên màn chi tiết, dùng cho "Mua ngay" — đi thẳng tới Checkout với
  /// đúng 1 sản phẩm này, không đụng tới giỏ hàng thật của người dùng.
  static CartItemModel buildBuyNowItem(ProductDetailLoaded detailState) {
    final detail = detailState.productDetail;
    final variant = detailState.selectedVariant;
    final optionIds = detailState.selectedOptionIds;
    final optionNames = detail.options
        .where((o) => optionIds.contains(o.id))
        .map((o) => o.optionName)
        .toList();
    final unitPrice = detailState.quantity > 0
        ? detailState.totalPrice / detailState.quantity
        : detailState.totalPrice;

    return CartItemModel(
      id: 'buy_now_${variant.id}',
      productId: detail.id,
      productName: detail.productName,
      image: variant.image ?? detail.image,
      shopId: detail.shopId,
      shopName: detail.shop?.shopName,
      variantId: variant.id,
      variantName: variant.variantName,
      selectedOptionIds: optionIds,
      selectedOptionNames: optionNames,
      quantity: detailState.quantity,
      unitPrice: unitPrice,
    );
  }

  static void _showSnackBar(
    BuildContext context,
    bool success,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? const Color(0xFF27AE60)
            : const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
