import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/cart/cart_cubit.dart';
import '../blocs/product_detail/product_detail_cubit.dart';
import '../blocs/product_detail/product_detail_state.dart';
import '../core/result.dart';
import '../di.dart';
import '../models/product_detail.model.dart';
import '../repositories/home_repository.dart';
import '../utils/cart_price_calculator.dart';

class QuickAddResult {
  final bool success;
  final String? errorMessage;

  const QuickAddResult._({required this.success, this.errorMessage});

  const QuickAddResult.success() : this._(success: true);

  const QuickAddResult.failure(String message)
      : this._(success: false, errorMessage: message);
}

/// Helper thêm sản phẩm hiện tại vào giỏ hàng mà không cần sửa logic ProductDetailCubit.
class CartActionHelper {
  CartActionHelper._();

  static bool addCurrentProductToCart(BuildContext context) {
    final detailState = context.read<ProductDetailCubit>().state;
    if (detailState is! ProductDetailLoaded) return false;

    getIt<CartCubit>().addFromProductDetail(detailState);
    return true;
  }

  /// Thêm nhanh từ danh sách: dùng variant mặc định, không tùy chọn thêm, số lượng 1.
  static Future<QuickAddResult> quickAddProduct(String productId) async {
    final repository = getIt<HomeRepository>();
    final res = await repository.fetchProductDetail(productId);

    if (res is Failure<ProductDetailModel>) {
      return QuickAddResult.failure(
        res.errorOrNull ?? 'Không thể thêm vào giỏ hàng',
      );
    }

    final detail = (res as Success<ProductDetailModel>).data;
    if (detail.variants.isEmpty) {
      return const QuickAddResult.failure('Sản phẩm chưa có phiên bản bán ra');
    }

    final defaultVariant = detail.variants.first;
    const selectedOptions = <String>{};
    final unitPrice = CartPriceCalculator.calculateUnitPrice(
      detail,
      defaultVariant,
      selectedOptions,
    );

    getIt<CartCubit>().addFromProductDetail(
      ProductDetailLoaded(
        productDetail: detail,
        selectedVariant: defaultVariant,
        selectedOptionIds: selectedOptions,
        quantity: 1,
        totalPrice: unitPrice,
      ),
    );

    return const QuickAddResult.success();
  }

  static Future<void> quickAddProductWithFeedback(
    BuildContext context,
    String productId, {
    required String successMessage,
    required String failureFallback,
  }) async {
    final result = await quickAddProduct(productId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? successMessage
              : (result.errorMessage ?? failureFallback),
        ),
        backgroundColor: result.success
            ? const Color(0xFF27AE60)
            : const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
