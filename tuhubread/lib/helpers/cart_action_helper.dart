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
    final canProceed = await _ensureSameShop(
      context,
      cubit,
      shopId: detail.shopId,
      shopName: detail.shop?.shopName,
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

    final cubit = getIt<CartCubit>();
    final canProceed = await _ensureSameShop(
      context,
      cubit,
      shopId: detail.shopId,
      shopName: detail.shop?.shopName,
    );
    if (!canProceed) return;
    if (!context.mounted) return;

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
  /// Nếu giỏ đang có sản phẩm của chi nhánh khác [shopId], hỏi xác nhận xoá
  /// giỏ cũ trước khi thêm. Trả về true nếu có thể tiếp tục thêm vào giỏ.
  static Future<bool> _ensureSameShop(
    BuildContext context,
    CartCubit cubit, {
    required String shopId,
    String? shopName,
  }) async {
    final items = cubit.state.items;
    if (items.isEmpty) return true;
    if (items.first.shopId == shopId) return true;

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppConfirmDialog.show(
      context,
      type: ConfirmDialogType.warning,
      title: l10n.cartShopConflictTitle,
      description: l10n.cartShopConflictMessage(
        items.first.shopName ?? '',
      ),
      confirmTitle: l10n.cartShopConflictConfirm,
      cancelTitle: l10n.cartCancel,
    );
    if (confirmed != true) return false;
    if (!context.mounted) return false;

    final cleared = await cubit.requestClearCart();
    if (!cleared && context.mounted) {
      _showSnackBar(context, false, l10n.cartShopConflictClearFailed);
    }
    return cleared;
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
