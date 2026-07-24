import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/cart/cart_cubit.dart';
import '../blocs/product_detail/product_detail_cubit.dart';
import '../blocs/product_detail/product_detail_state.dart';
import '../core/result.dart';
import '../di.dart';
import '../models/product_detail.model.dart';
import '../models/product_variant.model.dart';
import '../repositories/home_repository.dart';
import '../utils/cart_price_calculator.dart';
import '../widgets/size_select_bottom_sheet.dart';

/// Helper thêm sản phẩm hiện tại vào giỏ hàng mà không cần sửa logic ProductDetailCubit.
class CartActionHelper {
  CartActionHelper._();

  static bool addCurrentProductToCart(BuildContext context) {
    final detailState = context.read<ProductDetailCubit>().state;
    if (detailState is! ProductDetailLoaded) return false;

    getIt<CartCubit>().addFromProductDetail(detailState);
    return true;
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

    final unitPrice = CartPriceCalculator.calculateUnitPrice(
      detail,
      variant,
      selectedOptions,
    );

    getIt<CartCubit>().addFromProductDetail(
      ProductDetailLoaded(
        productDetail: detail,
        selectedVariant: variant,
        selectedOptionIds: selectedOptions,
        quantity: quantity,
        totalPrice: unitPrice * quantity,
      ),
    );

    _showSnackBar(context, true, successMessage);
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
