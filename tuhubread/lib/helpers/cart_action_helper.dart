import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/cart/cart_cubit.dart';
import '../blocs/product_detail/product_detail_cubit.dart';
import '../blocs/product_detail/product_detail_state.dart';
import '../core/result.dart';
import '../di.dart';
import '../models/cart_item.model.dart';
import '../models/product_detail.model.dart';
import '../models/product_variant.model.dart';
import '../repositories/home_repository.dart';
import '../utils/cart_price_calculator.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/size_select_bottom_sheet.dart';

/// Helper thêm sản phẩm hiện tại vào giỏ hàng mà không cần sửa logic ProductDetailCubit.
class CartActionHelper {
  CartActionHelper._();

  // Chặn double-tap trên nút "Thêm vào giỏ" / "Mua ngay" — nếu không, bấm
  // nhanh 2 lần trước khi request đầu hoàn tất sẽ tạo 2 cart item trùng nhau.
  static bool _isAddingCurrentProduct = false;

  static Future<bool> addCurrentProductToCart(BuildContext context) async {
    if (_isAddingCurrentProduct) return false;

    final detailState = context.read<ProductDetailCubit>().state;
    if (detailState is! ProductDetailLoaded) return false;

    _isAddingCurrentProduct = true;
    try {
      final cubit = getIt<CartCubit>();
      final detail = detailState.productDetail;

      final needsReplace = await _ensureSameShop(
        context,
        cubit,
        shopId: detail.shopId,
        shopName: detail.shop?.shopName,
      );
      if (needsReplace == null) return false;
      if (!context.mounted) return false;

      final result = await cubit.addFromProductDetail(detailState, replaceCart: needsReplace);
      return result is Success<List<CartItemModel>>;
    } finally {
      _isAddingCurrentProduct = false;
    }
  }

  /// Thêm nhanh từ danh sách (Home, gợi ý trong giỏ hàng...): nếu sản phẩm
  /// chỉ có một phiên bản thì thêm thẳng, ngược lại mở bottom sheet cho
  /// người dùng chọn size trước khi thêm vào giỏ.
  static final Set<String> _quickAddInFlight = {};

  static Future<void> quickAddProductWithFeedback(
    BuildContext context,
    String productId, {
    required String successMessage,
    required String failureFallback,
  }) async {
    if (_quickAddInFlight.contains(productId)) return;
    _quickAddInFlight.add(productId);
    try {
      await _quickAddProductWithFeedback(
        context,
        productId,
        successMessage: successMessage,
        failureFallback: failureFallback,
      );
    } finally {
      _quickAddInFlight.remove(productId);
    }
  }

  static Future<void> _quickAddProductWithFeedback(
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
    final needsReplace = await _ensureSameShop(
      context,
      cubit,
      shopId: detail.shopId,
      shopName: detail.shop?.shopName,
    );
    if (needsReplace == null) return;
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
      replaceCart: needsReplace,
    );
    if (!context.mounted) return;

    if (result is Success<List<CartItemModel>>) {
      _showSnackBar(context, true, successMessage);
    } else if (result is Failure<List<CartItemModel>>) {
      _showSnackBar(context, false, result.message);
    }
  }

  /// Giỏ hàng chỉ được chứa sản phẩm của 1 chi nhánh (giống ShopeeFood): thêm
  /// món → kiểm tra shopId → cùng quán thì cho thêm luôn, khác quán thì hỏi
  /// xoá giỏ hàng cũ trước khi thêm.
  ///
  /// Trả về `null` nếu người dùng huỷ (không thêm món). Ngược lại trả về giá
  /// trị cần truyền vào `replaceCart` khi gọi `addFromProductDetail`: `false`
  /// nếu giỏ đang trống/cùng quán, `true` nếu khác quán và đã xác nhận xoá —
  /// backend sẽ xoá giỏ cũ và thêm món mới trong đúng 1 request.
  static Future<bool?> _ensureSameShop(
    BuildContext context,
    CartCubit cubit, {
    required String shopId,
    String? shopName,
  }) async {
    final items = cubit.state.items;
    if (items.isEmpty) return false;
    if (items.first.shopId == shopId) return false;

    final oldShopName = items.first.shopName;
    final confirmed = await AppConfirmDialog.show(
      context,
      type: ConfirmDialogType.warning,
      title: "Xoá giỏ hàng cũ?",
      description:
          "Giỏ hàng của bạn đang có món của${oldShopName != null ? ' $oldShopName' : ' một cửa hàng khác'}."
          " Bạn có muốn xoá giỏ hàng cũ để đặt món${shopName != null ? ' từ $shopName' : ' mới'} không?",
      confirmTitle: "Xoá & thêm món mới",
      cancelTitle: "Hủy",
    );
    if (confirmed != true) return null;
    if (!context.mounted) return null;

    return true;
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
